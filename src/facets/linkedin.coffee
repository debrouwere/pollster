request = require 'request'
utils = require '../utils'

module.exports = (url, callback) ->
    params =
        uri: 'http://www.linkedin.com/countserv/count/share'
        qs:
            format: 'json'
            url: url
        json: yes

    request.get params, (err, response, result) ->
        if err or response.statusCode isnt 200
            callback new utils.CouldNotFetch()
        else
            callback null, result.count