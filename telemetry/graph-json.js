var fs = require('fs')
var axarTelemetry = require('axar-telemetry')

var interval = '1m'
var lookback = 1

console.log('starting')
axarTelemetry({dbName: 'eve-bpc-avg-mock'}, function (err, tele) {
  if (err) throw err
  console.log('connected')
  tele.graph({interval, lookback}, function (err, results) {
    if (err) throw err
    var outJSON = JSON.stringify(results, null, 2)
    fs.writeFileSync('./telemetry/telemetry-mock.json', outJSON)
    tele.client.close()
  })
})
