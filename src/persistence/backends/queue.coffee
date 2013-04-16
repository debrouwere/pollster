mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'

_ = require 'underscore'
utils = require '../../utils'
{Facet} = require '../facet'


class Queue
    rebuild: (callback) ->
        for page in watchlist
            @push 
 
    constructor: (@location, @credentials, @watchlist) ->



class exports.MongoDB extends Queue
    connect: (callback) ->
        manager = new mongodb.Server '127.0.0.1', 27017, {}
        client = new mongodb.Db 'pollster', dbManager, {w: 1}
        client.open (err, @client) =>
            callback err

    create: (callback) ->
        callback null

    finish: (err, url, facets, callback = ->) ->
        self = this
        return if err
            
        @watchlist.getScheduleFor url, (err, facets) ->
            # getScheduleFor should return an utils.timing.Schedule object
            # TODO: put in async.parallel
            null for facet, schedule of facets
                self.client.collection 'queue', (err, collection) ->
                    _id = "#{url}+#{facet}"
                    # remove url+facet from queue
                    collection.remove {_id}, (err) ->
                        # 2. calculate new interval / score
                        # (relative to now)
                        interval = schedule.next relative: yes
                        # 3. if interval is beyond window, move on
                        # 4. otherwise, add url+facet | score
                        if interval
                            self.push url, facet, interval

    pop: (query, callback) ->
        success = @finish.bind this

        client.collection 'queue', (err, collection) ->
            collection.find query, {safe: yes}, (err, documents) ->
                callback err, documents, success

    push: (object, callback) ->
        client.collection 'queue', (err, collection) ->
            collection.update object, {safe: yes, upsert: yes}, callback

# TODO: add Redis queue
class exports.Redis extends Queue
    connect: (callback) ->

    create: (callback) ->

    pop: (query, callback) ->

    push: (object, callback) ->