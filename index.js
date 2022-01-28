var mr = require('micro-request')
var async = require('async')
var sqlite3 = require('sqlite3').verbose()
var api_base = 'https://esi.evetech.net/latest/'
var fs = require('fs')
if (!fs.existsSync('./data/eve.sqlite')) {
  console.error('Please run ./get-db.sh first')
  process.exit(1)
}

// optional authentication
var accessToken = null

var hubs = {
  '10000002': 'The Forge',
  '10000043': 'Domain',
  '10000030': 'Heimatar',
  '10000032': 'Sinq Laison',
  '10000042': 'Metropolis'
}
var hub_ids = Object.keys(hubs)

var db = new sqlite3.Database('data/eve.sqlite')

const cliProgress = require('cli-progress');
const colors = require('ansi-colors');

function apiRequest (method, path, postData, onRes) {
  if (typeof postData === 'function') {
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
  //console.log('api req ', method, path)
  var req_start = new Date()
  var reqUrl = api_base + path
  var query = JSON.parse(JSON.stringify(postData))
  mr[method.toLowerCase()](reqUrl, {headers, query}, function (err, resp, body) {
    if (err) return onRes(err)
    var total_time = new Date().getTime() - req_start
    //console.log('completed', path, 'in', total_time, 'ms', resp.statusCode)
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
    onRes(null, body, resp)
  })
}

async.reduce(hub_ids, {blueprints: {}}, function (data, regionID, done) {
  // type: 1 is item_exchange

  // create new progress bar
  const b1 = new cliProgress.SingleBar({
    format: 'Searching ' + hubs['' + regionID] + ' |' + colors.cyan('{bar}') + '| {percentage}% || {value}/{total} Contracts || Speed: {speed}',
    barCompleteChar: '\u2588',
    barIncompleteChar: '\u2591',
    hideCursor: true
  });

  const speedData = [];

  apiRequest('GET', 'contracts/public/' + regionID + '/', {page: 1, type: 1}, function (err, body) {
    if (err) throw err
    b1.start(body.length, 0, {
      speed: 'calculating...'
    });

    function getTps (lookback) {
      lookback || (lookback = 5000);
      var currentOp = null
      var now = new Date().getTime()
      var lookbackOps = 0
      var idxBound = null
      for (var idx = 0; idx < speedData.length; idx++) {
        currentOp = speedData[idx]
        if (currentOp < now - lookback) {
          idxBound = idx;
          break;
        }
        lookbackOps++
      }
      if (typeof idxBound === 'number') {
        speedData.splice(0, idxBound)
      }
      var avgOps = lookbackOps / (lookback / 1000)
      return avgOps
    }

    async.reduce(body, {}, function (subtaskData, contract, subtaskDone) {
      apiRequest('GET', 'contracts/public/items/' + contract.contract_id + '/', function (err, body, resp) {
        if (err) return subtaskDone(err)
        // console.log('contract', contract)
        speedData.unshift(new Date().getTime())
        if (resp.statusCode === 204) {
          // console.log('expired!')
          
          b1.increment(1, {
            speed: getTps() + ' ops/sec'
          })
          return subtaskDone()
        }
        if (body.length === 1 && body[0].is_blueprint_copy && body[0].is_included) {
          var bpc = body[0]
          var bpc_key = '' + bpc.type_id
          data.blueprints[bpc_key] || (data.blueprints[bpc_key] = []);
          data.blueprints[bpc_key].push(contract.price)
        }
        b1.increment(1, {
          speed: getTps() + ' ops/sec'
        })
        subtaskDone()
      })
    }, function (err, subtaskResult) {
      if (err) return done(err)
      b1.stop()
      console.log('bpc prices', data.blueprints)
      process.exit()
    })
    //apiRequest('GET', 'contracts/public/items/' + /?datasource=tranquility&page=1
  })
}, function (err, result) {
  if (err) throw err
  console.log('complete')
  // db.close()
})
