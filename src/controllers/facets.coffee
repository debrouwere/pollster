{poll} = require '../models'


exports.list =
    get: (req, res) ->
        poll.urls req.options.urls, req.options.facets, (err, results) ->
            res.jsonp results, req.options.single

    put: (req, res) ->

exports.detail =
    get: exports.list.get
    
    put: (req, res) ->
