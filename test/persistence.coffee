should = require 'should'
utils = require '../src/utils'

describe 'We can store and query polled information using various backends', ->
    it 'can deflate data into a columnar format, and inflate them again', ->
        testObj =
            a1:
                a2: 'value1'
            b1:
                a2: 'value2'
                b2:
                    a3: 'value3'

        deflatedObj = utils.serialize.deflate testObj
        deflatedObj.should.have.property 'a1-a2'
        deflatedObj.should.have.property 'b1-a2'
        deflatedObj.should.have.property 'b1-b2-a3'
        inflatedObj = utils.serialize.inflate deflatedObj
        inflatedObj.should.eql testObj
        inflatedObj.b1.a2.should.eql 'value2'
        inflatedObj.b1.b2.a3.should.eql 'value3'