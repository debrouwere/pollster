_ = require 'underscore'

exports.deflate = deflate = (obj, parentKey='', connector='-') ->
    items = []
    for k, v of obj
        newKey = if parentKey then (parentKey + connector + k) else k
        if v instanceof Object
            items.push (_.pairs deflate v, newKey, connector)...
        else
            items.push [newKey, v]

    _.object items

exports.inflate = inflate = (flatObj, connector='-') ->
    if typeof flatObj is 'string' then flatObj = JSON.parse flatObj

    obj = {}

    for k, v of flatObj
        if (k.indexOf connector) isnt -1
            [baseKey, subKey...] = k.split connector
            subKey = subKey.join connector
            obj[baseKey] ?= {}
            _.extend obj[baseKey], inflate _.object [[subKey, v]]
        else
            obj[k] = v

    obj