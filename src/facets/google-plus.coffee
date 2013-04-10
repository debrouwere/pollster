request = require 'request'
{CouldNotFetch, Facet} = require '../models'

class module.exports extends Facet
    poll: (url, callback) ->
        # I'm cargo-culting a bit here -- I'm not sure which of these
        # parameters are strictly required.
        params =
            uri: 'https://clients6.google.com/rpc'
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

        request.post params, (err, response, result) ->
            if err or response.statusCode isnt 200
                callback new CouldNotFetch()
            else
                count = result.result.metadata.globalCounts.count
                callback null, count