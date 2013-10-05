# Service

This is a tiny framework that wraps [swagger](https://developers.helloreverb.com/swagger/), in order to eliminate
boilerplate code.

## API

#### createServer(port, host, handlers, models)

The `handlers` argument is an object containing zero or more handler objects.
The keys are handler nicknames, and associated values are `handler` objects.

A handler object should contain a `spec` and `action` property.
Here's an example of a handler:

```coffeescript
getPetById:
  spec:
    method:  "GET"
    path:  "/pet/{petId}"
    summary: "Returns a pet based on ID"
    notes: """
    """
    params: [
      swagger.pathParam("petId", "ID of pet that needs to be fetched", "string")
    ]
    responseClass: "Pet"
    errorResponses: [
      swagger.errors.invalid('id')
      swagger.errors.notFound('pet')
    ]
  action: (req, res, next) ->
    console.log "Fetching pet #{req.params.petId}."
    res.send {}
    next()
```
