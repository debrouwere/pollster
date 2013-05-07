async = require 'async'
_ = require 'underscore'
utils = require '../utils'
{Facet} = require './facet'
exports.CouldNotFetch = utils.CouldNotFetch
exports.Facet = Facet
exports.engines = require './engines'
exports.backends = require './backends'

exports.poll = poll = 
    facets: (url, facets, callback) ->
        tasks = {}
        for name, facet of facets
            # closure wrapper
            do (name, facet) ->
                tasks[name] = (done) -> facet.poll url, done
        
        async.parallel tasks, callback

    urls: (urls, facets, callback) ->
        tasks = {}
        for url in urls
            do (url) ->
                tasks[url] = (done) -> poll.facets url, facets, done
        # we can poll for many different things at once, but 
        # we shouldn't hammer any single API
        async.series tasks, callback


exports.process = process =
    # fetch, persist, call back
    task: (definition, callback) ->
        # each task comes with a callback to call once complete, 
        # which will remove the task from the queue
        {url, facet, notify, destination} = definition
        timestamp = utils.timing.now()
        facet.poll url, (err, data) ->
            if err then return callback err
            destination.put url, facet.name, timestamp, data, (err) ->
                notify err, callback

    tasks: (definitions, destination, callback) ->
        # as above, we process different facets in parallel, but only 
        # one query per facet at a time so as not to overload any 
        # individual external API with hundreds of requests per second
        definitionsByFacet = _.values _.groupBy definitions, (definition) -> definition.facet.name
        tasks = definitionsByFacet.map (facet) ->
            (done) ->
                facet.forEach (definition) -> definition.destination = destination
                async.mapSeries facet, process.task, done

        async.parallel tasks, callback