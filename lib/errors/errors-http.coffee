
# To add a new http error class, just extend from `HttpError`
# and add a `code` property.

class HttpError extends Error
    constructor: (options = {}) ->
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


class HttpMethodNotAllowedError extends HttpError
    code: 405


class HttpInternalServerError extends HttpError
    code: 500


module.exports = {
    HttpError
    HttpNotFoundError
    HttpBadRequestError
    HttpInternalServerError
    HttpMethodNotAllowedError
}