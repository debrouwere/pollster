request = require 'request'
utils = require '../utils'
{CouldNotFetch, Facet} = require '../persistence'

class module.exports extends Facet
    # TODO: support for options.parse which either keeps text as raw, 
    # or parses it into a data structure (e.g. for JSON, YAML, ...)
    poll: (url, options..., callback) ->
        options = utils.optional options
        params =
            uri: url

        console.log 'file poller received options', options

        request.get params, (err, response, body) ->
            if err
                callback new CouldNotFetch()
            else
                # TODO: make this smarter (parse more than just JSON)
                if options.parse then body = JSON.parse body
                callback null, body