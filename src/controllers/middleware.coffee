express = require 'express'
_ = require 'underscore'

params = 
    urls: (req) ->
        if req.query.url
            [req.query.url]
        else if req.query.urls
            req.query.urls.split ','
        else
            throw new Error "Need one or more URLs to fetch facets for."

    facets: (req) ->
        if req.params.facet
            _.object [[req.params.facet, req.app.facets[req.params.facet]]]
        else
            req.app.facets

exports.normalize =
    get: (req, res, next) ->
        # The REST API allows people to request one or more facets
        # for one or more urls, but the application itself should 
        # not have to worry about these differences.
        req.options = 
            urls: params.urls req
            facets: params.facets req
            single: req.query.url?

        res.jsonp = (response, single) ->
            if single
                response = (_.values response)[0]
            #res.jsonp response
            express.response.jsonp.call res, response

        next()