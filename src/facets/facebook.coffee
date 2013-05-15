request = require 'request'
{CouldNotFetch, Facet} = require '../persistence'
utils = require '../utils'
_ = require 'underscore'

class module.exports extends Facet
    poll: (url, options..., callback) ->
        options = utils.optional options
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