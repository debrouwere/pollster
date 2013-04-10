{parse} = require 'url'
request = require 'request'
_ = require 'underscore'
{CouldNotFetch, Facet} = require '../../src/models'

class module.exports extends Facet
    isProxy: yes

    poll: (url, callback) ->
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