exports.health =
    get: (req, res) ->
        res.jsonp yes

exports.queue =
    get: (req, res) ->
        res.jsonp {}