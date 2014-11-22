
_          = require 'lodash'
httpErrors = require './errors-http'


class ControllerError extends Error
    constructor: (@message) ->
        @type = @constructor.name
    toHttpError: (HttpErrorClass, data) ->
        options = {@message}
        options.data = data if data
        try return new HttpErrorClass(options)
        catch error
            throw new Error("Could not instantiate HttpErrorClass:\n#{error.toString()}")


class MissingArgumentError extends ControllerError
    constructor: (@argument) ->
        throw new ControllerErrorInvalidArgumentError('argument') if not _.isString(@argument)
        super "Missing required argument `#{@argument}`"
    toHttpError: ->
        super httpErrors.HttpBadRequestError, {@argument}


class InvalidArgumentError extends ControllerError
    # call this like so: new InvalidArgumentError({theInvalidArgument})
    constructor: (argument) ->
        throw new ControllerErrorInvalidArgumentError('argument') if not _.isObject(argument)
        @argument = Object.keys(argument)[0]
        @value    = argument[@argument]
        super "Invalid value `#{@value}` for argument `#{@argument}`"
    toHttpError: ->
        super httpErrors.HttpBadRequestError, {@argument, @value}


class ResourceAlreadyExistsError extends ControllerError
    # call this like so: new InvalidArgumentError({theInvalidArgument})
    constructor: (argument) ->
        throw new ControllerErrorInvalidArgumentError('argument') if not _.isObject(argument)
        @argument = Object.keys(argument)[0]
        @value    = argument[@argument]
        super "#{@argument} `#{@value}` already exists"
    toHttpError: ->
        super httpErrors.HttpBadRequestError, {@argument, @value}


class ResourceNotFoundError extends ControllerError
    # call this like so: new InvalidArgumentError({theInvalidArgument})
    constructor: (argument) ->
        throw new ControllerErrorInvalidArgumentError('argument') if not _.isObject(argument)
        @argument = Object.keys(argument)[0]
        @value    = argument[@argument]
        super "#{@argument} `#{@value}` was not found"
    toHttpError: ->
        super httpErrors.HttpNotFoundError, {@argument, @value}


class InternalError extends ControllerError
    constructor: (message) ->
        Error.captureStackTrace(this, InternalError)
        super message
    toHttpError: ->
        super httpErrors.HttpInternalServerError



module.exports = {
    ControllerError
    MissingArgumentError
    InvalidArgumentError
    ResourceNotFoundError
    ResourceAlreadyExistsError
    InternalError
}



class ControllerErrorInvalidArgumentError extends Error
    constructor: (argument) ->
        @mesage = "Argument `#{argument}` is invalid; Could not instantiate ControllerError."
