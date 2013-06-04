{parse} = require 'url'
request = require 'request'
_ = require 'underscore'
utils = require '../../src/utils'
{CouldNotFetch, Facet} = require '../../src/persistence'

class module.exports extends Facet
    isProxy: yes

    poll: (url, options..., callback) ->
        options = utils.optional options
        url = (parse url).pathname

        params =
            uri: 'http://content.guardianapis.com' + url
            qs:
                format: 'json'
                'show-fields': 'all'
            json: yes

        request.get params, (err, response, result) ->
            if err or response.statusCode isnt 200
                callback new CouldNotFetch()
            else
                callback null, result.response.content.fields