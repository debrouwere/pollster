# HTML and a screenshot for a specific page
# mainly useful for e.g. a front page

request = require 'request'
utils = require '../utils'
{CouldNotFetch, Facet} = require '../persistence'

class module.exports extends Facet