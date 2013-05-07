request = require 'request'
utils = require '../utils'
{CouldNotFetch, Facet} = require '../persistence'

class module.exports extends Facet
    # TODO: it should be possible
    poll: (url, options..., callback) ->
        options = utils.optional options
        params =
            uri: url

        request.get params, (err, response, result) ->
            # TODO: retry logic should not be in an individual facet, but 
            # it should be in the base class.
            if err or response.statusCode isnt 200 or typeof result is 'string'
                callback new CouldNotFetch()
            else
                # TODO: compare with previous fetch to see what's new
                # utils.track.pluck result, options.root, options.path
                changes = []
                callback null, null