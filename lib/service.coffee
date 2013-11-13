
{Buffer}   = require 'buffer'
restify    = require 'restify'
swagger    = require 'swagger-node-restify'
formatters = require './formatters'
errors     = require './errors'


copy = (object) ->
    JSON.parse JSON.stringify object


module.exports =
    errors: errors

    createService: (serviceId, version, handlers, models) ->
        throw new Error "`serviceId` parameter is required." if not serviceId
        throw new Error "`handlers` parameter is required." if not handlers
        throw new Error "`version` parameter is required." if not version
        throw new Error "`models` parameter is required." if not models

        app = restify.createServer {formatters}

        app.use restify.acceptParser app.acceptable
        app.use restify.CORS()
        app.use restify.fullResponse()
        app.use restify.bodyParser()
        app.use restify.queryParser()

        swagger.configureSwaggerPaths '', '/api/docs', ''
        swagger.addModels {models}
        swagger.setAppHandler app

        app.pre (req, res, next) ->
            if req.url in ['/docs', '/docs/']
                res.header 'Location', '/docs/index.html'
                res.send 302
            return next()

        app.get /^\/docs(\/.*)?$/, restify.serveStatic
            directory: __dirname + '/..'
            default:  'index.html'

        # Patching handlers
        Object.keys(handlers).forEach (handlerName) ->
            handler = handlers[handlerName]
            handler.spec.nickname = handlerName

        # Registering handlers
        console.log "Registering handlers:\n"
        Object.keys(handlers).forEach (handlerName) ->
            handler = handlers[handlerName]
            method  = handler.spec.method
            fn = swagger["add#{method}"]
            throw new Error "Handler spec has invalid method `#{method}`." if not fn
            console.log "#{handler.spec.method} #{handler.spec.path}"
            console.log "#{handler.spec.summary}\n"
            fn.call swagger, handler

        return new Service serviceId, version, app, swagger


class Service
    constructor: (@id, @version, @app, @swagger) ->
    listen: (port, host) ->
        port ?= 80
        host ?= 'localhost'
        console.log "Listening on http://#{host}:#{port}\n"

        console.log "Docs can be found at:"
        console.log "http://#{host}:#{port}/docs"

        @swagger.configure "http://#{host}:#{port}", "#{@version}"
        @app.listen port, host
        return @
