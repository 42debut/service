
# To add a new http error class, just extend from `HttpError`
# and add a `code` property.

class HttpError extends Error

    constructor: (options = {}) ->
        if typeof options is "string"
            [options, message] = [{}, options]
            options.message = message
        @code    = options.code    or @code or 500
        @message = options.message or 'Server Error'
        @data    = options.data    or {}
        @type    = options.type    or @constructor.name

    serialize: ->
        result = {@code, @message, @type}
        result.data = @data if @data
        return result

    toString: ->
        JSON.stringify @serialize(), null, 2


class HttpNotFoundError extends HttpError
    code: 404


class HttpBadRequestError extends HttpError
    code: 400


class HttpUnauthorizedError extends HttpError
    code: 401


class HttpForbiddenError extends HttpError
    code: 403


class HttpMethodNotAllowedError extends HttpError
    code: 405


class HttpInternalServerError extends HttpError
    code: 500


module.exports = {
    HttpError
    HttpNotFoundError
    HttpBadRequestError
    HttpUnauthorizedError
    HttpForbiddenError
    HttpMethodNotAllowedError
    HttpInternalServerError
}