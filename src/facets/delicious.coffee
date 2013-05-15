request = require 'request'
utils = require '../utils'
{CouldNotFetch, Facet} = require '../persistence'

class module.exports extends Facet
    poll: (url, options..., callback) ->
        options = utils.optional options
        params =
            uri: 'http://feeds.delicious.com/v2/json/urlinfo/data'
            qs:
                url: url
            json: yes

        request.get params, (err, response, result) ->
            # TODO: retry logic should not be in an individual facet, but 
            # it should be in the base class.
            if err or response.statusCode isnt 200
                callback new CouldNotFetch()
            else
                callback null, result[0].total_posts