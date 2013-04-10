request = require 'request'
{CouldNotFetch, Facet} = require '../models'
_ = require 'underscore'

class module.exports extends Facet
    fetch: (url, callback) ->
        params =
            uri: 'https://graph.facebook.com/'
            qs:
                ids: url
            json: yes

        request.get params, (err, response, result) ->
            if err or response.statusCode isnt 200
                callback new CouldNotFetch()
            else
                result = (_.values result)[0]
                shares = result.shares
                commentsBox = result.comments or false
                counts =
                    'shares': shares
                    'comments-box': commentsBox

                callback null, counts