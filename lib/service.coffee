
Promise = require 'bluebird'
Promise.longStackTraces()

bunyan     = require 'bunyan'
restify    = require 'restify'
swagger    = require 'swagger-node-restify'
formatters = require './formatters'
errors     = require './errors'


module.exports =

    restify: restify

    swagger: swagger

    errors: errors

    Service: ({name, version, handlers, models}) ->
        throw new Error "`name` parameter is required."     if not name
        throw new Error "`handlers` parameter is required." if not handlers
        throw new Error "`version` parameter is required."  if not version

        server = restify.createServer {formatters}

        server.use restify.acceptParser server.acceptable
        server.use restify.CORS()
        server.use restify.fullResponse()
        server.use restify.bodyParser()
        server.use restify.queryParser()

        swagger.configureSwaggerPaths '', '/api/docs', ''
        swagger.addModels {models}
        swagger.setAppHandler server

        server.pre (req, res, next) ->
            if req.url in ['/docs', '/docs/']
                res.header 'Location', '/docs/index.html'
                res.send 302
            return next()

        server.get /^\/docs(\/.*)?$/, restify.serveStatic
            directory: __dirname + '/..'
            default:  'index.html'

        # server.on 'after', restify.auditLogger
        #   log: bunyan.createLogger
        #     name: 'audit',
        #     stream: process.stdout

        handlers = processHandlers(handlers)

        console.log "Available Swagger Endpoints:\n"
        Object.keys(handlers).forEach (handlerName) ->
            handler = handlers[handlerName]
            console.log "  #{handler.spec.method} #{handler.spec.path}"
            console.log "  --> #{handler.spec.summary}\n"

        return new Service {name, version, server, swagger, handlers, models}


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

        # Wrap handler action for promise support and better error handling
        (name, handler) ->
            {action} = handler
            handler.action = (req, res, next) ->
                try
                    Promise.cast(action(req)).done (result) ->
                        res.send 200, result
                        next()
                catch error
                    # FIXME: Handle our own http error types.
                    console.error error.stack
                    httpError = new errors.HttpInternalServerError()
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



class Service

    constructor: ({@name, @version, @server, @swagger, @handlers, @models}) ->

    listen: (port, host, base) ->
        port ?= 80
        host ?= 'localhost'
        console.log "`#{@name}` listening on http://#{host}:#{port}\n"

        console.log "Docs can be found at:"
        console.log "http://#{host}:#{port}/docs\n\n"

        @swagger.configure base or "http://#{host}:#{port}", "#{@version}"
        @server.listen port, host
        return @
