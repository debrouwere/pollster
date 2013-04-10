###
1. use the right backend classes (Mongo, Redis etc. depending on what's 
   configured)
2. read/write data to/from the database
3. work via the Facet class (to process data before writing and after reading)
4. pass off
###

options = 
    # a part of `req.app`, so usable in any controller as well as in user code
    engine: null
    range: null
    index: null
    facets: []

exports.history =
    read: (options) ->

    write: (options) ->

    update: (options) ->

    delete: (options) ->

    size: (options) ->

exports.settings = 'TODO'

exports.queue = 'TODO'

exports.cache = 'TODO'

# last hour, last day totals (amount of queries split by facet etc.)
exports.health = 'TODO'