
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


# Don't forget to add your new error class to this object,
# otherwise it won't be exported.
module.exports = errorTypes = {
    HttpError
    HttpNotFoundError
    HttpBadRequestError
    HttpInternalServerError
    HttpMethodNotAllowedError
}


module.exports.utils =

    getHttpErrorFromCode: do ->
        codeMap = {}
        for type, HttpError of errorTypes
            httpError = new HttpError()
            continue if httpError.code is undefined
            codeMap[httpError.code] = HttpError
        return (errorCode) -> codeMap[errorCode]

    isRestifyError: (error) ->
        error.statusCode isnt undefined

    createFromRestifyError: (error) ->
        if not @isRestifyError(error)
            throw new Error("Error object is not a restify error")

        HttpErrorClass = @getHttpErrorFromCode(error.statusCode)
        if not HttpErrorClass
            throw new Error("Could not map restify error with code `#{error.statusCode}` to an HttpError class.")

        httpError = do ->
            options = {message:error.message, code:error.statusCode}
            return new HttpErrorClass options

        switch httpError.code
            when 404 then do ->
                resource = httpError.message.match(/(.*) does not exist/)?[1]
                if resource
                    httpError.message = "Resource `#{resource}` does not exist."
                    httpError.data.resource = resource
            when 405 then do ->
                method = httpError.message.match(/(.*) is not allowed/)?[1]
                if method
                    httpError.message = "Method `#{method}` is not allowed."
                    httpError.data.method = method

        return httpError
