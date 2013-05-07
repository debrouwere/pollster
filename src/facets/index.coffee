fs = require 'fs'
fs.path = require 'path'
_ = require 'underscore'

here = (segments...) -> fs.path.join __dirname, segments...

module.exports = facets = {}

for facetPath in fs.readdirSync here './'
    extension = fs.path.extname facetPath
    executable = extension in ['.coffee', '.js']
    self = (facetPath.indexOf 'index') isnt -1
    continue if self or not executable

    facetName = fs.path.basename facetPath, extension
    facetFile = here './', facetPath
    handler = require facetFile
    facets[facetName] = _.extend {name: facetName}, new handler()
