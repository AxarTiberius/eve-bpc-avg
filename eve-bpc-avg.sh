#!/usr/bin/env node

var mr = require('micro-request')
var async = require('async')
var sqlite3 = require('sqlite3').verbose()
var api_base = 'https://esi.evetech.net/latest/'
var fs = require('fs')
var csvStringify = require('csv-stringify/sync').stringify
/*
if (!fs.existsSync('./data/eve.sqlite')) {
  console.error('Please run ./get-db.sh first')
  process.exit(1)
}
*/

var taskLimit = 64, sortIndex = 3, pageLimit = 1000, apiTimeout = 5000;

// optional authentication
var accessToken = null

const csvHeaders = [
  'typeID',
  'invType.typeName',
  //'invType.description',
  'prices.length',
  'meanPrice',
  'medianPrice',
  'modePrice'
]

const hubs = {
  '10000002': 'The Forge',
  '10000043': 'Domain',
  '10000030': 'Heimatar',
  '10000032': 'Sinq Laison',
  '10000042': 'Metropolis'
}
const hub_ids = Object.keys(hubs)

const db = new sqlite3.Database('eve-bpcs.sqlite')

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
  const req_start = new Date()
  const reqUrl = api_base + path
  const query = JSON.parse(JSON.stringify(postData))
  ;(function retry () {
    mr[method.toLowerCase()](reqUrl, {headers, query, timeout: apiTimeout}, function (err, resp, body) {
      if (err) {
        if (err.code === 'ECONNREFUSED' || err.code === 'ETIMEDOUT') {
          //console.error('warning: connection error for ' + path + ', retrying')
          return retry()
        }
        return onRes(err)
      }
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
          //console.error('unexpected api response: ' + body)
          return retry()
          body = {}
        }
      }
      if (!body) {
        body = {}
      }
      onRes(null, body, resp)
    })
  })()
}

var rows = [
  csvHeaders
], results = {blueprints: {}}

async.reduce(hub_ids, null, function (_ignore, regionID, done) {
  // type: 1 is item_exchange
  const speedData = [];
  var page = 1;

  async.doWhilst(function (pageCb) {
    // create new progress bar
    const b1 = new cliProgress.SingleBar({
      format: 'Searching ' + hubs['' + regionID] + ' page ' + page + ' |' + colors.cyan('{bar}') + '| {percentage}% || {value}/{total} Contracts || Speed: {speed}',
      barCompleteChar: '\u2588',
      barIncompleteChar: '\u2591',
      hideCursor: true
    });

    apiRequest('GET', 'contracts/public/' + regionID + '/', {page, type: 1}, function (err, body) {
      if (err) {
        return pageCb(err)
      }
      var fetchLength = body.length || 0;
      if (!fetchLength) return pageCb(null, 0)
      b1.start(body.length, 0, {
        speed: 'calculating...'
      });

      function getTps (lookback) {
        lookback || (lookback = 5000);
        var currentOp = null
        var now = new Date().getTime()
        var lookbackOps = 0
        var idxBound = null
        var reverseSpeedData = speedData.reverse()
        for (var idx = 0; idx < reverseSpeedData.length; idx++) {
          currentOp = reverseSpeedData[idx]
          if (currentOp < now - lookback) {
            idxBound = idx;
            break;
          }
          lookbackOps++
        }
        if (typeof idxBound === 'number' && speedData.length > idxBound) {
          //speedData.splice(0, idxBound)
        }
        var avgOps = lookbackOps / (lookback / 1000)
        return avgOps
      }

      var subtasks = body.map(function (contract) {
        return function (contractDone) {
          apiRequest('GET', 'contracts/public/items/' + contract.contract_id + '/', function (err, body, resp) {
            if (err) {
              return contractDone(err)
            }
            // console.log('contract', contract)
            speedData.push(new Date().getTime())
            if (resp.statusCode === 204) {
              // console.log('expired!')
              b1.increment(1, {
                speed: getTps() + ' ops/sec'
              })
              return contractDone()
            }
            if (body.length === 1 && body[0].is_blueprint_copy && body[0].is_included) {
              var bpc = body[0]
              var bpc_key = '' + bpc.type_id
              results.blueprints[bpc_key] || (results.blueprints[bpc_key] = []);
              results.blueprints[bpc_key].push(contract.price)
            }
            b1.increment(1, {
              speed: getTps() + ' ops/sec'
            })
            contractDone()
          })
        }
      })

      async.parallelLimit(subtasks, taskLimit, function (err) {
        if (err) return done(err)
        b1.stop()
        pageCb(null, fetchLength)
      })
    })
  }, function (lastFetchLength, testCb) {
    page++
    testCb(null, lastFetchLength === pageLimit)
  }, function (err, results) {
    if (err) return done(err)
    done()
  })
}, function (err) {
  if (err) return done(err)
  async.mapValues(results.blueprints, function (prices, typeID, done) {
    db.get('SELECT * FROM invTypes WHERE typeID = ?', [typeID], function (err, invType) {
      if (err) return done(err)
      if (!invType) {
        console.error('warning: invType not found: ', typeID)
      }
      invType || (invType = {typeName: '', description: ''});

      var totalPrice = prices.reduce(function (prev, cur) {
        return prev + cur
      }, 0)
      var meanPrice = totalPrice / prices.length
      var medianPrice = prices[0]
      if (prices.length > 1) {
        var midPoint = Math.floor(prices.length / 2)
        medianPrice = prices[midPoint]
      }
      var occur = {}
      prices.forEach(function (price) {
        var k = price + ''
        if (!occur[k]) occur[k] = 0;
        occur[k]++
      })
      var maxOccur = 0, modePrice = 0;
      Object.keys(occur).forEach(function (k) {
        if (occur[k] > maxOccur) {
          maxOccur = occur[k]
          modePrice = Number(k)
        }
      })
      rows.push([
        Number(typeID),
        invType.typeName,
        // invType.description,
        prices.length,
        Math.round(meanPrice),
        medianPrice,
        modePrice
      ])
      done()
    })
  }, function (err) {
    if (err) throw err
    console.log('data collected! writing CSV...')
    var file = fs.createWriteStream('./output.csv')
    file.once('finish', function () {
      console.log('wrote', './output.csv with', rows.length, 'rows')
      db.close()
      process.exit(0)
    })
    rows.sort(function (cur, prev) {
      if (typeof cur[0] === 'string') {
        // header
        //console.log('cur', cur)
        return -1
      }
      if (cur[sortIndex] > prev[sortIndex]) {
        return -1
      }
      if (cur[sortIndex] == prev[sortIndex]) {
        return 0
      }
      return 1
    })
    rows.forEach(function (row) {
      file.write(csvStringify([row]))
    })
    file.end()
  })
})
