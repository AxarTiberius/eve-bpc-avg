var fs = require('fs')
var axarTelemetry = require('axar-telemetry')
var async = require('async')
var timebucket = require('timebucket')

var interval = '30m'
var lookback = 3
var collSuffix = process.env.SIM ? '-mock' : ''

console.log('starting')
axarTelemetry({dbName: 'eve-bpc-avg' + collSuffix}, function (err, tele) {
  if (err) throw err
  console.log('connected')
  var bounds = [], runId
  async.series([
    // get latest runId and end bound
    function (cb) {
      tele.collection.find({})
        .sort({timestamp: -1})
        .limit(1)
        .toArray(function (err, docs) {
          if (err) return cb(err)
          if (!docs.length) return cb(new Error('no events in db'))
          runId = docs[0].runId
          bounds[1] = docs[0].timestamp
          return cb()
        })
    },
    // get start bound
    function (cb) {
      tele.collection.find({runId})
        .sort({timestamp: 1})
        .limit(1)
        .toArray(function (err, docs) {
          if (err) return cb(err)
          if (!docs.length) return cb(new Error('no events in db'))
          bounds[0] = docs[0].timestamp
          return cb()
        })
    }
  ], withBounds)
  function withBounds (err) {
    if (err) throw err
    var queryBase = {
      runId,
      timestamp: {$gte: bounds[0]}
    }
    console.log('queryBase', queryBase)
    // enum event types
    tele.collection.distinct('type', {runId}, function (err, eventTypes) {
      if (err) throw err
      eventTypes.push('all')
      async.reduce(eventTypes, {}, function (memo, eventType, cb) {
        var query = JSON.parse(JSON.stringify(queryBase))
        if (eventType !== 'all') {
          query.type = eventType
        }
        tele.graph({interval, lookback, query, start: bounds[0]}, function (err, graph) {
          if (err) throw err
          memo[eventType] = graph
          cb(null, memo)
        })
      }, function (err, results) {
        if (err) throw err
        var p = './telemetry/results.json'
        var outJSON = JSON.stringify(results, null, 2)
        fs.writeFileSync(p, outJSON)
        tele.client.close()
        console.log('wrote', p)
      })
    })
  }
})
