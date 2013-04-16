exports.traverse = traverse = (obj, path) ->
    for segment in path.split '.'
        obj = obj[segment]
    obj

exports.pluck = (feed, root, path) ->
    urls = []
    for item in traverse feed, root
        urls.push traverse item, path

    urls

exports.new = (feed, callback) ->
    callback new Error "Not implemented yet."