
errors = require './errors'


formatter = (fn) -> (req, res, body) ->
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

    data = fn(body)

    res.setHeader 'Content-Length', Buffer.byteLength(data)
    return data


module.exports =
    'text/csv':         formatter (data) -> data
    'application/json': formatter (data) -> JSON.stringify(data)
