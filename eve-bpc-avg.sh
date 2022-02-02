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

var taskLimit = 64, sortIndex = 14, pageLimit = 1000, apiTimeout = 5000;

// optional authentication
var accessToken = null

const csvHeaders = [
  'typeID',
  'typeName',
  //'invType.description',
  'soloContracts',
  'meanSoloPrice',
  'medianSoloPrice',
  'modeSoloPrice',
  'minSoloPrice',
  'maxSoloPrice',
  'packageContracts',
  'meanPackagePrice',
  'medianPackagePrice',
  'modePackagePrice',
  'minPackagePrice',
  'maxPackagePrice',
  'minPrice'
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
], results = {items: {}}

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
            var items = (body && body.forEach) ? body : [];
            items.forEach(function (item) {
              var itemKey = '' + item.type_id
              if (item.is_included) {
                results.items[itemKey] || (results.items[itemKey] = {soloPrices: [], packagePrices: []})
                if (body.length === 1) {
                  results.items[itemKey].soloPrices.push(contract.price / item.quantity);
                }
                else {
                  results.items[itemKey].packagePrices.push(contract.price / item.quantity);
                }
              }
            })
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
  async.mapValues(results.items, function (item, typeID, done) {
    db.get('SELECT * FROM invTypes WHERE typeID = ?', [typeID], function (err, invType) {
      if (err) return done(err)
      if (!invType) {
        // console.error('warning: invType not found: ', typeID)
        apiRequest('GET', 'universe/types/' + typeID + '/', function (err, body, resp) {
          if (err) return done(err)
          if (!body || !body.name) {
            console.error('warning: invType lookup failed: ', typeID)
            return done()
          }
          withInv({typeID: typeID, typeName: body.name, description: body.description})
        })
      }
      else {
        withInv(invType)
      }

      function withInv (invType) {
        var totalSoloPrice = item.soloPrices.reduce(function (prev, cur) {
          return prev + cur
        }, 0)
        var meanSoloPrice = item.soloPrices.length ? totalSoloPrice / item.soloPrices.length : ''
        var medianSoloPrice = item.soloPrices.length ? item.soloPrices[0] : ''
        function onlyUnique (value, index, self) {
          return self.indexOf(value) === index;
        }
        var uniqueSolo = item.soloPrices.filter(onlyUnique);
        if (uniqueSolo.length > 1) {
          var midPoint = Math.floor(uniqueSolo.length / 2)
          medianSoloPrice = uniqueSolo[midPoint]
        }
        var soloOccur = {}
        item.soloPrices.forEach(function (price) {
          var k = price + ''
          if (!soloOccur[k]) soloOccur[k] = 0;
          soloOccur[k]++
        })
        var maxSoloOccur = 0, modeSoloPrice = 0;
        Object.keys(soloOccur).forEach(function (k) {
          if (soloOccur[k] > maxSoloOccur) {
            maxSoloOccur = soloOccur[k]
            modeSoloPrice = Number(k)
          }
        })
        var minSoloPrice = item.soloPrices.length ? Math.min.apply(Math, item.soloPrices) : ''
        var maxSoloPrice = item.soloPrices.length ? Math.max.apply(Math, item.soloPrices) : ''

        var totalPackagePrice = item.packagePrices.reduce(function (prev, cur) {
          return prev + cur
        }, 0)
        var meanPackagePrice = item.packagePrices.length ? totalPackagePrice / item.packagePrices.length : ''
        var medianPackagePrice = item.packagePrices.length ? item.packagePrices[0] : ''
        var uniquePackage = item.packagePrices.filter(onlyUnique);
        if (uniquePackage.length > 1) {
          var midPoint = Math.floor(uniquePackage.length / 2)
          medianPackagePrice = uniquePackage[midPoint]
        }
        var packageOccur = {}
        item.packagePrices.forEach(function (price) {
          var k = price + ''
          if (!packageOccur[k]) packageOccur[k] = 0;
          packageOccur[k]++
        })
        var maxPackageOccur = 0, modePackagePrice = 0;
        Object.keys(packageOccur).forEach(function (k) {
          if (packageOccur[k] > maxPackageOccur) {
            maxPackageOccur = packageOccur[k]
            modePackagePrice = Number(k)
          }
        })
        var minPackagePrice = item.packagePrices.length ? Math.min.apply(Math, item.packagePrices) : ''
        var maxPackagePrice = item.packagePrices.length ? Math.max.apply(Math, item.packagePrices) : ''

        var minPrice = minSoloPrice
        if (!minPrice) {
          minPrice = minPackagePrice
        }

        function csvNumber (num) {
          return typeof num === 'number' ? Math.round(num) : ''
        }

        rows.push([
          Number(typeID),
          invType.typeName,
          // invType.description,
          item.soloPrices.length,
          csvNumber(meanSoloPrice),
          csvNumber(medianSoloPrice),
          csvNumber(modeSoloPrice),
          csvNumber(minSoloPrice),
          csvNumber(maxSoloPrice),
          item.packagePrices.length,
          csvNumber(meanPackagePrice),
          csvNumber(medianPackagePrice),
          csvNumber(modePackagePrice),
          csvNumber(minPackagePrice),
          csvNumber(maxPackagePrice),
          csvNumber(minPrice)
        ])
        done()
      }
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
