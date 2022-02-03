var fs = require('fs')
var assert = require('assert')

var parser = require('./parser.js')

var result = parser(fs.readFileSync('./paste_example.txt', 'utf8'))

console.log('result', result)
