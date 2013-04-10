{Pollster} = require '../src'

pollster = new Pollster()
pollster.use 'twitter'
pollster.use 'facebook'

pollster.start 'server', 3000
#pollster.start 'poller'