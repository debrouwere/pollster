express = require 'express'
_ = require 'underscore'

params = 
    urls: (req) ->
        if req.query.url
            list = [req.query.url]
        else if req.query.urls
            list = req.query.urls.split ','
        else
            throw new Error "Need one or more URLs to fetch facets for."

        list.map decodeURIComponent

    facets: (req) ->
        # the middleware route specifies the facet (if any) as an asterisk, 
        # so it's not available under req.params.facet as it would be in a
        # regular route
        facet = req.params[0]?.replace /\//g, ''

        if facet
            _.object [[facet, req.app.facets[facet]]]
        else
            req.app.facets

exports.normalize =
    all: (req, res, next) ->
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