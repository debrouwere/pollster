request = require 'request'
{CouldNotFetch, Facet} = require '../models'

class module.exports extends Facet
    poll: (url, callback) ->
        params =
            uri: 'http://urls.api.twitter.com/1/urls/count.json'
            qs:
                url: url
            json: yes

        request.get params, (err, response, result) ->
            # TODO: retry logic should not be in an individual facet, but 
            # it should be in the base class.
            if err or response.statusCode isnt 200 or typeof result is 'string'
                callback new CouldNotFetch()
            else
                callback null, result.count