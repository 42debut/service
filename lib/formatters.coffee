
errors = require './errors'


module.exports =

    'application/json': (req, res, body) ->

        if body instanceof errors.http.HttpError
            body = body.serialize()
            res.statusCode = body.code

        else if body instanceof Error

            if errors.utils.isSwaggerError(body)
                body = errors.utils.createFromSwaggerError(body)
                res.statusCode = body.code
            else if errors.utils.isRestifyError(body)
                body = errors.utils.createFromRestifyError(body)
                res.statusCode = body.code
            else
                console.error("Unhandled internal error type.")

        else if Buffer.isBuffer body
            body = body.toString('base64')

        data = JSON.stringify body

        res.setHeader 'Content-Length', Buffer.byteLength(data)
        return data
