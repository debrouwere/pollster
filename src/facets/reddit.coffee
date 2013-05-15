# Reddit:http://buttons.reddit.com/button_info.json?url=%%URL%%

request = require 'request'
utils = require '../utils'
{CouldNotFetch, Facet} = require '../persistence'

class module.exports extends Facet