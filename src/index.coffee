###
TODO: it might make sense to cluster the server, one process per CPU
###

exports.facets = require './facets'
exports.persistence = require './persistence'
exports.Pollster = (require './server').Pollster