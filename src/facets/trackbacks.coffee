###
* use GA or SiteCatalyst, whatever is activated
* we can cache trackbacks and only add new ones, but we'd want
to update the tweetcounts on each tick -- with (url, tweetcount) 
pairs, you can figure out what trackbacks are legit
###

request = require 'request'
{CouldNotFetch, Facet} = require '../models'

class module.exports extends Facet