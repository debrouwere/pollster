###
# ?url and ?detail parameters
# also allow bulk with ?urls
GET /
# PUT works like GET, but also starts tracking the article
PUT /
GET /:facet/
# when adding in facet data from an external source instead of our polling mechanism
POST /:facet/
# auto-track content in a feed
GET, PUT, DELETE /feeds/
# calculate the amount of API requests we'll be executing per minute for every facet, 
# what errors we've gotten recently, and also what's currently in the queue
GET /health/
GET /queue/
###

fs = require 'fs'
fs.path = require 'path'
express = require 'express'
_ = require 'underscore'
controllers = require './controllers'
middleware = controllers.middleware
facets = require './facets'
poller = require './poller'

class exports.Pollster
    route: (endpoint, controller) ->
        for method, action of controller
            @app[method] endpoint, action

    view: (endpoint, controller) ->
        @app.get '/views' + endpoint, controller

    use: (facet, src) ->
        if src
            @app.facets[facet] = new (require src)()
        else
            if facet of @availableFacets
                @app.facets[facet] = @availableFacets[facet]
            else
                throw new Error "Can't find #{facet}"

    constructor: (@app = express()) ->
        @availableFacets = _.clone facets
        @app.facets = {}

        @app.use express.bodyParser()
        @app.use express.methodOverride()
        @app.use @app.router

        @route '/facets*', middleware.normalize
        @route '/health', controllers.health.health
        @route '/queue', controllers.health.queue
        @route '/facets', controllers.facets.list
        @route '/facets/:facet', controllers.facets.detail
        @route '/feeds', controllers.feeds

    listen: (port = 3000) ->
        @app.listen port
        facets = (_.keys @app.facets).join(', ')
        console.log "Pollster listening on port #{port}. Tracking #{facets}."

    start: (component='server', port=3000) ->
        if component is 'poller'
            poller.start()
        else
            @listen port