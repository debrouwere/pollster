request = require 'request'

params = 
    uri: 'http://localhost:3334/facets/'
    qs:
        url: 'http://www.theguardian.com/travel/gallery/2013/sep/13/travel-picture-quiz-name-that-bridge'
    body:
        cron: '*/2'
    json: yes        


request.put params, (err, res, body) ->
    console.log body