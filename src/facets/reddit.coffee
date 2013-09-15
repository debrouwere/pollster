request = require 'request'
utils = require '../utils'

module.exports = (url, callback) ->
    params =
        uri: 'http://buttons.reddit.com/button_info.json'
        qs:
            format: 'json'
            url: url
        json: yes

    request.get params, (err, response, result) ->
        if err or response.statusCode isnt 200
            callback new utils.CouldNotFetch()
        else if result.data.children.length
            ups = 0
            downs = 0
            for child in result.data.children
                ups += child.data.ups
                downs += child.data.downs
            callback null, {ups, downs}
        else
            callback null, undefined
