mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'
async = require 'async'
_ = require 'underscore'
utils = require '../utils'

module.exports = 
    MongoDB:
        connect: (location, callback) ->
            defaults =
                host: '127.0.0.1'
                port: 27017
                name: 'pollster'
            location = _.defaults location, defaults

            manager = new mongodb.Server location.host, location.port, {}
            client = new mongodb.Db location.name, manager, {w: 1}
            client.open callback

        collection: (location, name, callback) ->
            connect = (done) -> module.exports.MongoDB.connect location, done
            select = (client, done) -> 
                client.collection name, (err, collection) -> 
                    done err, collection, client

            async.waterfall [connect, select], callback

    DynamoDB:
        # allows for a callback for consistency, but doesn't need one
        connect: (location, callback=utils.noop) ->
            AWS.config.update location
            client = new AWS.DynamoDB().client
            process.nextTick -> callback null, client
            return client

        interfaceFor: (client, name, options={}) ->
            {deflate, inflate, serialize, deserialize} = module.exports.DynamoDB
            if options.serialized
                preprocess = (obj) -> serialize obj, options.keys
                postprocess = deserialize
            else
                preprocess = deflate
                postprocess = inflate

            collection = 
                name: name

                client: client

                waitOnState: (expectedState, callback) ->
                    wait = ->
                        q = {TableName: name}
                        client.describeTable q, (err, result) ->
                            if err then return callback err

                            currentState = result.Table.TableStatus
                            if currentState is expectedState
                                callback null
                            else
                                console.log \
                                    "[DYNAMODB] Waiting for table #{name} to enter #{expectedState}.
                                    (Currently #{currentState})"
                                setTimeout wait, 5000

                    wait()

                exists: (callback) ->
                    client.listTables _.once (err, result) ->
                        if _.contains result.TableNames, name
                            callback null, yes
                        else
                            callback null, no

                waitUntilGone: (callback) ->
                    wait = ->
                        collection.exists (err, exists) ->
                            if err then return callback err

                            if exists
                                console.log \
                                    "[DYNAMODB] Waiting for table #{name} to disappear"
                                setTimeout wait, 5000
                            else
                                callback null

                    wait()

                createTable: (params, callback) ->
                    collection.exists (err, exists) ->
                        if err
                            return callback err
                        else if exists
                            return callback null
                        else
                            client.createTable params, (err) ->
                                if err
                                    return callback err
                                else
                                    collection.waitOnState 'ACTIVE', callback

                scan: (callback) ->
                    q =
                        TableName: name

                    client.scan q, _.once (err, result) ->
                        items = result.Items.map postprocess
                        callback err, items

                get: (key..., value, callback) ->
                    if _.isEmpty key
                        key = options.pk
                    else
                        key = key[0]

                    q = 
                        TableName: name
                        Key: {}
                    q.Key[key] = 
                        'S': value

                    client.getItem q, _.once (err, result) =>
                        if err
                            callback err
                        else
                            if 'Item' of result then item = postprocess result.Item
                            callback null, item

                put: (item, options..., callback) ->
                    q = 
                        TableName: name
                        Item: (preprocess item)
                    client.putItem q, callback

                remove: (key..., value, callback) ->
                    if _.isEmpty key
                        key = options.pk
                    else
                        key = key[0]

                    q = 
                        TableName: name
                        Key: {}
                    q.Key[key] =
                        'S': value

                    client.deleteItem q, callback

                deleteTable: (callback) ->
                    q = 
                        TableName: name

                    client.deleteTable q, (err) ->
                        collection.waitUntilGone callback

        deflate: (structure) ->
            obj = utils.serialize.deflate structure
            description = {}
            for k, v of obj
                switch typeof v
                    when 'number'
                        description[k] = {N: v.toString()}
                    when 'string'
                        description[k] = {S: v}

            description

        inflate: (description) ->
            obj = {}
            for k, el of description
                for type, v of el
                    switch type
                        when 'N'
                            obj[k] = parseFloat v
                        when 'S'
                            obj[k] = v
            utils.serialize.inflate obj

        serialize: (obj, keys) ->
            serialized = {}
            for key, type of keys
                column = {}
                column[type] = obj[key]
                serialized[key] = column
            serialized.data = {S: (JSON.stringify obj)}

            serialized

        deserialize: (description) ->
            JSON.parse description.data['S']

    Redis:
        # allows for a callback for consistency, but doesn't need one
        connect: (location, callback=utils.noop) ->
            if location
                client = redis.createClient location.port, location.host
            else
                client = redis.createClient()
            callback null, client
            return client