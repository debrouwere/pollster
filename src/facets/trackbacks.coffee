###
* use GA or SiteCatalyst, whatever is activated
* we can cache trackbacks and only add new ones, but we'd want
to update the tweetcounts on each tick -- with (url, tweetcount) 
pairs, you can figure out what trackbacks are legit
###

request = require 'request'
utils = require '../utils'
{CouldNotFetch, Facet} = require '../persistence'

class module.exports extends Facet