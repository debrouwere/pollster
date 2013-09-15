request = require 'request'
utils = require '../utils'

module.exports = (url, callback) ->
    params =
        uri: 'http://api.facebook.com/restserver.php'
        qs:
            method: 'links.getStats'
            format: 'json'
            urls: url
        json: yes

    request.get params, (err, response, result) ->
        if err or response.statusCode isnt 200
            callback new utils.CouldNotFetch()
        else
            counts =
                comments: result[0].click_count
                likes: result[0].like_count
                shares: result[0].share_count
            callback null, counts