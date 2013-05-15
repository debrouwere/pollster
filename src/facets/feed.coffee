request = require 'request'
feedparser = require 'feedparser'
utils = require '../utils'
{CouldNotFetch, Facet} = require '../persistence'

class module.exports extends Facet
    poll: (url, options..., callback) ->
        options = utils.optional options
        params =
            uri: url

        feedparser.parseUrl params, (err, meta, articles) ->
            if err or response.statusCode isnt 200
                callback new CouldNotFetch()
            else
                callback null, articles