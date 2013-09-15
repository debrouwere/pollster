_ = require 'underscore'

SECOND = 1000
MINUTE = SECOND * 60
HOUR = MINUTE * 60
DAY = HOUR * 24
WEEK = DAY * 7
MONTH = WEEK * 4.345
YEAR = WEEK * 52

milliseconds = ms  = exports.milliseconds = exports.ms  = (n) -> n
seconds      = sec = exports.seconds      = exports.sec = (n) -> n * SECOND
minutes      = min = exports.minutes      = exports.min = (n) -> n * MINUTE
hours        = hrs = exports.hours        = exports.hrs = (n) -> n * HOUR
days         = d   = exports.days         = exports.d   = (n) -> n * DAY
weeks        = wks = exports.weeks        = exports.wks = (n) -> n * WEEK
years        = yrs = exports.years        = exports.yrs = (n) -> n * YEAR

# the time that has passed since `start`, in milliseconds
exports.delta = (start) ->
    stop = new Date().getTime()
    stop - start

exports.now = now = ->
    new Date().getTime()

exports.after = (n) ->
    new Date now() + n