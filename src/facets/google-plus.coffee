request = require 'request'
utils = require '../utils'

module.exports = (url, callback) ->
    key = process.env.GOOGLEPLUS_SECRET_KEY

    # I'm cargo-culting a bit here -- I'm not sure which of these
    # parameters are strictly required.
    params =
        uri: 'https://clients6.google.com/rpc'
        qs: {}
        body: 
            method: 'pos.plusones.get'
            id: 'p'
            params: 
                nolog: yes
                id: url
                source: 'widget'
            jsonrpc: '2.0'
            key: 'p'
            apiVersion: 'v1'
        json: yes

    #if key
    #    params.qs.key = key

    request.post params, (err, response, result) ->
        if err or response.statusCode isnt 200 or not result.result?
            callback new utils.CouldNotFetch result?.error?.message
        else
            count = result.result.metadata.globalCounts.count
            callback null, count