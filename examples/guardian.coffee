{Pollster} = require '../src'

here = (src) -> __dirname + src

pollster = new Pollster()
pollster.use 'twitter'
pollster.use 'facebook'
pollster.use 'guardian-fields', here '/guardian/content-api.coffee'
pollster.listen 3000