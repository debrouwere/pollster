express = require 'express'
utils = require './utils'
timing = utils.timing
controllers = require './controllers'
facets = require './facets'
middleware = controllers.middleware
_ = require 'underscore'
request = require 'request'


app = express()

# The core of Pollster is an express.js application.
# We're defining the REST API here, but keeping other
# parts of Pollster in a subclass below: `exports.Pollster`
class Server
    route: (endpoint, controller) ->
        for method, action of controller
            @app[method] endpoint, action

    view: (endpoint, controller) ->
        @app.get '/views' + endpoint, controller

    constructor: ->
        @app = express()

        @app.pollster = this
        @app.use express.bodyParser()
        @app.enable 'strict routing'

        @route '/facets*', middleware.normalize
        @route '/facets/', controllers.facets.list
        @route '/facets/velocity/', controllers.facets.velocity
        @route '/facets/:facet/', controllers.facets.detail
        @route '/latest/', controllers.facets.latest

    listen: (port = 3000) ->
        @app.listen port
        console.log "Pollster listening on port #{port}."


class exports.Pollster extends Server
    _use: (facetName, instance) ->
        @app.facets[facetName] = instance
        @configuration.facets = _.uniq @configuration.facets.concat facetName 

    use: (facet, src) ->
        if src
            instance = _.extend {name: facet}, new (require src)()
            @_use facet, instance
        else
            if facet of @availableFacets
                @_use facet, @availableFacets[facet]
            else
                throw new Error "Can't find #{facet}"

    configure: (key, value) ->
        @configuration[key] = value

    track: (url, parameters, callback) ->
        # parameters determine exactly how to track things, 
        # options enable or disable certain special features
        # we can do with the results from our tracking
        parameters = _.defaults parameters, @configuration

        params =
            # TODO: make this configurable
            uri: 'http://localhost:3333/'
            json: yes
            body:
                name: url
                type: 'sqs'
                destination: @destination
                schedule:
                    cron: parameters.cron
                    decay: parameters.decay
                    start: utils.get parameters.start
                    stop: utils.get parameters.stop
                payload:
                    url: url

        request.post params, callback

    listen: (port) ->
        super port
        facets = (_.keys @app.facets).join(', ')
        console.log "Tracking #{facets}."

    constructor: (@destination, configuration={}) ->
        super()

        @app.pollster = this
        @availableFacets = _.clone facets
        # TODO: this is wrong.
        @app.facets = {}

        defaults = 
            facets: []
            start: -> new Date()
            stop: -> timing.after timing.days 7
            cron: '*/5'
            decay: (timing.days 1)

        @configuration = _.defaults configuration, defaults
