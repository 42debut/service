
frisby      = require 'frisby'
TestService = require './test-service'

endpoint = (x) -> "http://localhost:2999#{x}"


service = new TestService()
service.listen 2999


frisby.create('Test a simple GET request')
.get(endpoint('/ping'))
.expectStatus(200)
.expectBodyContains('pong')
.toss()

frisby.create('Check if sync error (from lib) is being properly returned')
.get(endpoint('/errors/sync/lib'))
.expectStatus(500)
.toss()

frisby.create('Check if sync error (from native) is being properly returned')
.get(endpoint('/errors/sync/native'))
.expectStatus(500)
.toss()

frisby.create('Check if async error is being properly thrown')
.get(endpoint('/errors/async'))
.expectStatus(500)
.toss()

frisby.create('Check if checkAuthorization rejection works')
.get(endpoint('/authorization/forbidden/always'))
.expectStatus(403)
.toss()

frisby.create('Check if checkAuthorization rejection works with an error')
.get(endpoint('/authorization/forbidden/error'))
.expectStatus(403)
.expectJSON(
    message:'Your role is not good.'
)
.toss()

frisby.create('Check if checkAuthorization success works')
.get(endpoint('/authorization/open'))
.expectStatus(200)
.toss()


_finishCallback = jasmine.Runner.prototype.finishCallback
jasmine.Runner.prototype.finishCallback = ->
    _finishCallback.bind(this)()
    service.close()
