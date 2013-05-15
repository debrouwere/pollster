request = require 'request'
utils = require '../utils'
{CouldNotFetch, Facet} = require '../persistence'

class module.exports extends Facet
    poll: (url, options..., callback) ->
        options = utils.optional options
        params =
            uri: 'http://www.linkedin.com/countserv/count/share'
            qs:
                format: 'json'
                url: url
            json: yes

        request.get params, (err, response, result) ->
            if err or response.statusCode isnt 200
                callback new CouldNotFetch()
            else
                callback null, result.count