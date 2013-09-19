request = require 'request'

key = process.env.GOOGLEPLUS_SECRET_KEY
uri = 'https://www.googleapis.com/plus/v1/people/108189587050871927619'

params =
    uri: uri
    qs: {}
    json: yes

if key
    params.qs.key = key

request.get params, (err, response, result) ->
    console.log response, result