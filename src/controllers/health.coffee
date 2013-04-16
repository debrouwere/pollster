# calculate the amount of API requests we'll be executing per minute for every facet, 
# what errors we've gotten recently, and also what's currently in the queue

exports.health =
    get: (req, res) ->
        res.jsonp yes

exports.queue =
    get: (req, res) ->
        res.jsonp {}