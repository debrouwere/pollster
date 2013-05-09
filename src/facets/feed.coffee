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
            if err or response.statusCode isnt 200 or typeof result is 'string'
                callback new CouldNotFetch()

            if (response.headers['content-type'].indexOf 'json') isnt -1
                utils.traverse.pluck result, options.root, options.path
            else

            else
                # TODO: compare with previous fetch to see what's new
                
                changes = []
                callback null, null