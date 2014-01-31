

httpErrors = require './errors-http'


module.exports =

    getHttpErrorFromCode: do ->
        codeMap = {}
        for type, HttpError of httpErrors
            httpError = new HttpError()
            continue if httpError.code is undefined
            codeMap[httpError.code] = HttpError
        return (errorCode) -> codeMap[errorCode]


    isSwaggerError: (error) ->
        (error.statusCode isnt undefined) and \
        (error.we_cause isnt undefined)


    isRestifyError: (error) ->
        (error.statusCode isnt undefined) and \
        (error.we_cause is undefined)


    createFromSwaggerError: (error) ->
        if not @isSwaggerError(error)
            throw new Error("Error object is not a swagger error")

        HttpErrorClass = @getHttpErrorFromCode(error.statusCode)
        if not HttpErrorClass
            throw new Error("Could not map swagger error with code `#{error.statusCode}` to an HttpError class.")

        httpError = do ->
            options = {message:error.message, code:error.statusCode}
            return new HttpErrorClass options

        switch httpError.code
            when 404 then do ->
                resource = httpError.message
                httpError.message = "Resource `#{resource}` does not exist."
                httpError.data.resource = resource

        return httpError


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

