
Promise = require 'bluebird'


{EventEmitter} = require 'events'
bunyan         = require 'bunyan'
restify        = require 'restify'
swagger        = require 'swagger-node-restify'
AuthLib        = require 'auth-lib'
formatters     = require './formatters'
errors         = require './errors'


module.exports =

    restify: restify

    swagger: swagger

    errors: errors

    Service: ({name, version, handlers, models, log}) ->
        throw new Error "`name` parameter is required."     if not name
        throw new Error "`handlers` parameter is required." if not handlers
        throw new Error "`version` parameter is required."  if not version

        server = restify.createServer {name, formatters, log}

        headers =
            token: '42-auth-token'
            id:    '42-id'
            name:  '42-name'
            org:   '42-org'
            role:  '42-role'

        Object.keys(headers).forEach (key) ->
            restify.CORS.ALLOW_HEADERS.push(headers[key])

        server.use restify.acceptParser server.acceptable
        server.use restify.CORS()
        server.use restify.fullResponse()
        server.use restify.bodyParser()
        server.use restify.queryParser()

        server.use (req, res, next) ->
            req.user = AuthLib.getUser(req)
            next()

        swagger.configureSwaggerPaths '', '/api/docs', ''
        swagger.addModels {models:(models or {})}
        swagger.setAppHandler server

        server.pre (req, res, next) ->
            if req.url in ['/docs', '/docs/']
                res.header 'Location', '/docs/index.html'
                res.send 302
            return next()

        server.get /^\/docs(\/.*)?$/, restify.serveStatic
            directory: __dirname + '/..'
            default:  'index.html'

        # server.on 'uncaughtException', (req, res, route, error) ->
        #     console.error '--> Uncaught Exception in route'
        #     console.error error.trace or error
        #     res.send error

        # server.on 'after', restify.auditLogger
        #   log: bunyan.createLogger
        #     name: 'audit',
        #     stream: process.stdout

        handlers = processHandlers(handlers)

        console.log "\nAvailable Swagger Endpoints:\n"
        Object.keys(handlers).forEach (handlerName) ->
            handler = handlers[handlerName]
            console.log "  #{handler.spec.method} #{handler.spec.path} (#{handler.spec.nickname})"
            console.log "  --> #{handler.spec.summary or handler.spec.description}\n"

        service = new Service {name, version, server, swagger, handlers, models}

        shutDownService = (signal) ->
            console.log "#{signal} received, shutting down server gracefully."
            service.close().then ->
                console.log "All connections closed successfully."

        handleSignal = (signal) ->
            process.once signal, ->
                shutDownService(signal).finally ->
                    process.kill(process.pid, signal)

        handleSignal('SIGTERM')
        handleSignal('SIGINT')
        handleSignal('SIGUSR2')

        return service


processHandlers = do ->

    processors = [

        # Validate handler, requires `spec` and `action` property.
        (name, handler) ->
            {spec, action} = handler
            throw new Error("Missing `spec` property in handler `#{name}`") if not spec
            throw new Error("Missing `action` property in handler `#{name}`") if not action
            return handler

        # Patch handler nickname, if needed
        (name, handler) ->
            handler.spec.nickname ?= name
            return handler


        # Add role checking step and promise support
        (name, handler) ->
            {action, checkAuthorization} = handler

            checkAuthorization ?= -> true

            if typeof checkAuthorization is "string"
                checkAuthorization = do ->
                    role = checkAuthorization
                    return (user) -> user.role is role

            handler.action = (req, res, next) -> Promise.try ->
                user = AuthLib.getUser(req)
                Promise.cast(checkAuthorization user, req)
                .then (isAuthorized) ->
                    throw new errors.http.HttpForbiddenError() if not isAuthorized
                    return Promise.cast(action.call handler, req, res)

            return handler


        # Wrap handler action for better error handling
        (name, handler) ->
            {action} = handler

            handler.action = (req, res, next) ->

                action.call(handler, req, res)
                .then (result) ->
                    if handler.render
                        handler.render(result, res)
                    else
                        res.send 200, result
                    next()
                .catch (error) ->
                    if error instanceof (errors.http.HttpError)
                        console.error "--> INFO: HTTP error in action of handler `#{name}`."
                        httpError = error
                    else if error instanceof (errors.controller.InternalError)
                        console.error "--> WARNING: Internal controller error in action of handler `#{name}`."
                        httpError = error.toHttpError()
                    else if error instanceof (errors.controller.ControllerError)
                        console.error "--> INFO: Controller error in action of handler `#{name}`."
                        httpError = error.toHttpError()
                        httpError.type = error.type
                    else
                        console.error "--> WARNING: Unhandled error in action of handler `#{name}`."
                        httpError = new errors.http.HttpInternalServerError()
                    console.error error.stack or error + '\n'
                    res.send httpError.code, httpError
                    next()

            return handler

        # Register handler with swagger
        (name, handler) ->
            {method} = handler.spec
            fn = swagger["add#{method}"]
            throw new Error "Handler `#{name}` spec has invalid method `#{method}`." if not fn
            fn.call swagger, handler
            return handler
    ]

    return (handlers) ->
        Object.keys(handlers).reduce ((result, handlerName) ->
            handler = handlers[handlerName]
            processors.forEach (fn) ->
                handler = fn(handlerName, handler)
            result[handlerName] = handler
            return result
        ), {}



class Service extends EventEmitter

    constructor: ({@name, @version, @server, @swagger, @handlers, @models}) ->

    listen: (port, host, base, callback) ->

        [port, host, base, callback] = \
        switch arguments.length
            when 0 then do ->
                return [null, null, null, null]
            when 1 then do ->
                return [port, null, null, null] if typeof port in ["string", "number"]
                return [null, null, null, port]
            when 2 then do ->
                return [port, host, null, null] if typeof host is "string"
                return [port, null, null, host]
            when 3 then do ->
                return [port, host, base, null] if typeof host is "string" and typeof base is "string"
                return [port, host, null, base]
            else do ->
                return [port, host, base, callback]

        port ?= 80
        host ?= 'localhost'
        base ?= "http://#{host}:#{port}"

        console.log "`#{@name}` listening on http://#{host}:#{port}\n"

        console.log "Docs can be found at:"
        console.log "http://#{host}:#{port}/docs\n\n"

        @swagger.configure base, "#{@version}"
        @server.listen port, host, callback
        return @

    close: (timeout = 30000) -> new Promise (resolve, reject) =>
        timeout = Math.max(0, parseInt(timeout))
        throw new Error("`timeout` argument `#{timeout}` is not valid.") if Number.isNaN(timeout)
        timedOut = false
        timer = setTimeout ->
            timedOut = true
            return reject new Error("server timed out while closing")
        , timeout
        @server.close ->
            clearTimeout(timer)
            return if timedOut
            return resolve()
