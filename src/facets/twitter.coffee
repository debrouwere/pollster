request = require 'request'
utils = require '../utils'
{CouldNotFetch, Facet} = require '../persistence'

class module.exports extends Facet
    poll: (url, options..., callback) ->
        options = utils.optional options
        params =
            # put the url in `uri` rather than `qs` because Twitter
            # needs URLs to *not* be urlencoded
            uri: 'http://urls.api.twitter.com/1/urls/count.json?url=' + url
            json: yes

        request.get params, (err, response, result) ->
            # TODO: retry logic should not be in an individual facet, but 
            # it should be in the base class.
            if err or response.statusCode isnt 200 or typeof result is 'string'
                callback new CouldNotFetch()
            else
                callback null, result.count