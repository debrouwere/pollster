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
        # each task comes with a callback (`notify`) to call once complete, 
        # which will remove the task from the queue
        options = definition.facet.options
        {url, facet, notify, destination, watchlist} = definition
        timestamp = utils.timing.now()

        poll = _.partial facet.poll, url, options

        store = (data, done) ->
            if not data? then return done null, null

            # TODO
            # The proper way to solve this would be for facets (or specific fetches)
            # to have the ability to define a `serialize: yes/no` option that determines
            # whether we'll try to split content out into fields or not.
            # Also a `store: yes/no` option -- remember that DynamoDB doesn't allow
            # for more than 64k in a field.
            if options.watchlist
                console.log '[TESTING / WARNING] not saving watchlist to history'
                return done null, data

            destination.put url, facet.name, timestamp, data, (err) -> done err, data

        watch = (uri, done) ->
            watchlist.watch uri, {options: {replace: no}}, done   

        # we can treat a polled feed as a watchlist
        # feeds will often contain older items we're already tracking, 
        # and {replace: no} tells the watchlist that it shouldn't 
        # change any of the parameters for those uris already in
        # the system
        ifWatchList = (data, done) ->
            if not options.watchlist then return done null
            console.log "[WATCHLIST] Processing #{url} as a watchlist"
            uris = utils.traverse.pluck data, options.root, options.path
            async.each uris, watch, done

        notify = _.partial notify, null

        async.waterfall [poll, store, ifWatchList, notify], callback


    tasks: (definitions, backends, callback) ->
        facetToTask = (facet) ->
            (done) ->
                facet.forEach (definition) ->
                    definition.destination = backends.history
                    definition.watchlist = backends.watchlist
                async.mapSeries facet, process.task, done

        # as above, we process different facets in parallel, but only 
        # one query per facet at a time so as not to overload any 
        # individual external API with hundreds of requests per second
        definitionsByFacet = _.values _.groupBy definitions, (definition) -> definition.facet.name
        tasks = definitionsByFacet.map facetToTask
        async.parallel tasks, callback