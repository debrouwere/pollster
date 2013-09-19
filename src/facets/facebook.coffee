_ = require 'underscore'
request = require 'request'
utils = require '../utils'

###
TODO: perhaps create a separate facet for: 
https://graph.facebook.com/fql?q=SELECT%20like_count,%20total_count,%20share_count,%20click_count,%20comment_count%20FROM%20link_stat%20WHERE%20url%20=%20%22
... for people who want more detailed facebook reporting
###

module.exports = (url, callback) ->
    params =
        uri: 'https://graph.facebook.com/'
        qs:
            ids: url
        json: yes

    request.get params, (err, response, result) ->
        if err or response.statusCode isnt 200
            callback new utils.CouldNotFetch err
        else
            result = (_.values result)[0]
            shares = result.shares
            commentsBox = result.comments or false
            counts =
                'shares': shares
                'comments-box': commentsBox

            callback null, counts