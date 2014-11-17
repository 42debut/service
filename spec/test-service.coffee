
Promise = require 'bluebird'
{Service, swagger, restify, errors} = require '../lib/service'



Handlers =

    ping:
        spec:
            description: "Replies back with pong"
            method:      "GET"
            path:        "/ping"
            notes:       ""
            params: [
            ]
            errorResponses: [
            ]
        action: (req, res) -> "pong"


    echo:
        spec:
            description: "Echoes back the body parameter"
            method:      "POST"
            path:        "/echo"
            notes:       ""
            params: [
            ]
            errorResponses: [
            ]
        action: (req, res) -> req.body


    errorSyncFromLib:
        spec:
            description: "Throwing an error synchronously in action (error from lib)"
            method:      "GET"
            path:        "/errors/sync/lib"
            notes:       ""
            params: [
            ]
            errorResponses: [
            ]
        action: (req, res) -> throw new errors.http.HttpInternalServerError("lib sync error")


    errorSyncFromNative:
        spec:
            description: "Throwing an error synchronously in action (native error)"
            method:      "GET"
            path:        "/errors/sync/native"
            notes:       ""
            params: [
            ]
            errorResponses: [
            ]
        action: (req, res) -> throw new Error("native sync error, if you see this that's a good thing!")


    errorAsync:
        spec:
            description: "Rejecting the promise in the action handler"
            method:      "GET"
            path:        "/errors/async"
            notes:       ""
            params: [
            ]
            errorResponses: [
            ]
        action: (req, res) -> new Promise (resolve, reject) -> reject(new errors.http.HttpInternalServerError("promise async error"))


    authorizationForbidden:
        spec:
            description: "Role check that always fails"
            method:      "GET"
            path:        "/authorization/forbidden/always"
            notes:       ""
            params: [
            ]
            errorResponses: [
            ]
        checkAuthorization: ->
            return false
        action: (req, res) ->
            return "you should not see this"


    authorizationOpen:
        spec:
            description: "Role check that always succeeds"
            method:      "GET"
            path:        "/authorization/open"
            notes:       ""
            params: [
            ]
            errorResponses: [
            ]
        checkAuthorization: ->
            return true
        action: (req, res) ->
            return "you should be able to see this"


    authorizationForbiddenWithError:
        spec:
            description: "Role check that always fails, by throwing an error"
            method:      "GET"
            path:        "/authorization/forbidden/error"
            notes:       ""
            params: [
            ]
            errorResponses: [
            ]
        checkAuthorization: ->
            throw new errors.http.HttpForbiddenError("Your role is not good.")
        action: (req, res) ->
            return "you should not be able to see this"



module.exports = (port) ->
    return new Service
        name:    'test-service'
        version:  '0.0'
        handlers: Handlers