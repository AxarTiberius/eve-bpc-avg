var mr = require('micro-request')
var async = require('async')
var sqlite3 = require('sqlite3').verbose()
var api_base = 'https://esi.evetech.net/latest/'
var fs = require('fs')
if (!fs.existsSync('./data/eve.sqlite')) {
  console.error('Please run ./get-db.sh first')
  process.exit(1)
}

var hub_ids = [
  10000002, // The Forge
  10000043, // Domain
  10000030, // Heimatar
  10000032, // Sinq Laison
  10000042 // Metropolis
]
// optional authentication
var accessToken = null

var db = new sqlite3.Database('data/eve.sqlite')

function apiRequest (method, path, postData, onRes) {
  if (typeof postData == 'function') {
    onRes = postData
    postData = null
  }
  postData || (postData = {});
  postData.datasource || (postData.datasource = 'tranquility');
  var headers = {
    'Accept': 'application/json',
    'Cache-Control': 'no-cache'
  }
  if (accessToken) {
    headers['Authorization'] = 'Bearer ' + accessToken
  }
  console.log('api req ', method, path)
  var req_start = new Date()
  var reqUrl = api_base + path
  var query = JSON.parse(JSON.stringify(postData))
  mr[method.toLowerCase()](reqUrl, {headers, query}, function (err, resp, body) {
    if (err) return onRes(err)
    var total_time = new Date().getTime() - req_start
    console.log('completed', path, 'in', total_time, 'ms')
    if (Buffer.isBuffer(body)) {
      body = body.toString('utf8')
    }
    if (typeof body === 'string' && body.length) {
      try {
        body = JSON.parse(body)
      }
      catch (e) {
        console.error('unexpected api response: ' + body)
        body = {}
      }
    }
    if (!body) {
      body = {}
    }
    onRes(null, body)
  })
}

async.reduce(hub_ids, {blueprints: {}}, function (data, regionID, done) {
  // type: 1 is item_exchange
  apiRequest('GET', 'contracts/public/' + regionID + '/', {page: 1, type: 1}, function (err, body) {
    if (err) throw err
    async.reduce(body, {}, function (_, contract, subtaskDone) {
      console.log('contract', contract)
      process.exit()
    }, function (err, subtaskResult) {

    })
    //apiRequest('GET', 'contracts/public/items/' + /?datasource=tranquility&page=1
  })
}, function (err, result) {
  if (err) throw err
  console.log('complete')
  // db.close()
})
