var MongoClient = require('mongodb').MongoClient

function connectBackend (options, cb) {
  if (typeof options === 'function') {
    cb = options
    options = {}
  }
  if (!options.url) {
    options.url = 'mongodb://localhost:27017'
  }
  if (!options.dbName) {
    options.dbName = process.env.SIM ? 'eve-bpc-avg-mock' : 'eve-bpc-avg'
  }
  var client = new MongoClient(options.url)
  client.connect(function (err) {
    if (err) return cb(err)
    var db = client.db(options.dbName)
    cb(null, client, db)
  })
}

module.exports = connectBackend
