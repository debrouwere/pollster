{poll} = require '../persistence'

exports.list =
    get: (req, res) ->
        # TODO: actually the polling should happen elsewhere, this controller
        # should simply query the database (and that function should poll only
        # for proxied facets)
        # 
        # TODO: support ?history=true where we return not just the total but 
        # return the entire polling history
        poll.urls req.options.urls, req.options.facets, (err, results) ->
            res.jsonp results, req.options.single

    # put works exactly like GET, but it also adds the URL to our tracker
    put: (req, res) ->
        exports.list.get req, res
        # req.app.queue.write(...)


exports.detail =
    get: exports.list.get
    
    put: exports.list.put

    post: (req, res) ->
        # when adding in facet data from an external source instead of our polling mechanism