#!/usr/bin/env node

var axarTelemetry = require('axar-telemetry')
var mr = require('micro-request')
var async = require('async')
var apiBase = 'https://esi.evetech.net/latest/'
var fs = require('fs')
var csvStringify = require('csv-stringify/sync').stringify
var assert = require('assert')
var querystring = require('querystring')
var idgen = require('idgen')
var runId = idgen(6)
console.log('runId', runId)

var dbName = process.env.SIM ? 'eve-bpc-avg-mock' : 'eve-bpc-avg'
var barPrefix = process.env.SIM ? '(MOCK) ' : ''

var sampleContractsPage = require('./contracts_jita_p1.json')
var sampleContractItems = require('./contract.json')
var sampleOrdersPage = require('./orders_jita_p220.json')
var sampleType = require('./sample_type.json')

var
  taskLimit =         8,
  sortIndex =         20,
  pageLimit =         1000,
  apiTimeout =        5000,
  itemLookupLimit =   8,
  itemLookupTimeout = 0,
  orderProgressMax =  250,
  throttleTime =      5000

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
  'meanMarketPrice',
  'medianMarketPrice',
  'modeMarketPrice',
  'marketLiquidity',
  'minMarketPrice',
  'maxMarketPrice',
  'minPrice',
  'marketType',
  'minPriceRegionID',
  'minPriceRegionName'
]

const hubs = require('./regions.json')
const hub_ids = Object.keys(hubs)

const db = require('axar-sde')()

const cliProgress = require('cli-progress');
const colors = require('ansi-colors');

var connectBackend = require('./mongo-backend')
var tele, mongo, cache, mongoClient

var apiRequest = function (method, path, postData, onRes) {
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
  var contractsPublicMatch = path.match(/^contracts\/public\/([\d]+)\/$/)
  var type, cacheExpire
  if (contractsPublicMatch) {
    type = 'list_contracts'
    mockResponseTime = 1200
    mockResponse = sampleContractsPage
    if (contractsPublicMatch[1] === '10000002') {
      if (postData.page === 25) {
        mockResponse = [].slice.call(mockResponse, 1)
      }
    }
    else if (postData.page === 5) {
      mockResponse = [].slice.call(mockResponse, 1)
    }
    // On ESI's side, 30 mins
    // 20 hours
    cacheExpire = 10e6*7.2
  }
  var contractsPublicItemsMatch = path.match(/^contracts\/public\/items\/([\d]+)\/$/)
  if (contractsPublicItemsMatch) {
    type = 'contract_items'
    // On ESI's side, 1 hour
    // 90 days
    cacheExpire = 10e8*7.776
  }
  var marketOrdersMatch = path.match(/^markets\/([\d]+)\/orders\/$/)
  if (marketOrdersMatch) {
    type = 'list_orders'
    // On ESI's side, 5 mins
    // 20 hours
    cacheExpire = 10e6*7.2
  }
  var typeLookupMatch = path.match(/^universe\/types\/([\d]+)\/$/)
  if (typeLookupMatch) {
    type = 'type_lookup'
    // On ESI's side, 1 day
    // 90 days
    cacheExpire = 10e8*7.776
  }

  var cacheKey = method + '+' + apiBase + path
  if (Object.keys(postData).length) {
    cacheKey += '?' + querystring.stringify(postData)
  }
  // console.log('cacheKey', cacheKey)
  if (!type) {
    throw new Error('unknown API request: ' + cacheKey)
  }

  cache.findOne({_id: cacheKey, timestamp: {$gt: new Date().getTime() - cacheExpire}}, function (err, doc) {
    if (err) return onRes(err)
    if (doc) {
      return onRes(null, doc.body, {statusCode: doc.statusCode})
    }
    doRequest()
  })
  function doRequest () {
    //console.log('api req ', method, path)
    var reqUrl = apiBase + path
    var query = JSON.parse(JSON.stringify(postData))
    ;(function retry () {
      // (end request)
      setTimeout(function () {
        var reqStart = new Date()
        mr[method.toLowerCase()](reqUrl, {headers, query, timeout: apiTimeout}, function (err, resp, body) {
          //console.log(body)
          if (err) {
            if (err.code === 'ECONNREFUSED' || err.code === 'ETIMEDOUT') {
              //console.error('warning: connection error for ' + path + ', retrying')
              return retry()
            }
            return onRes(err)
          }
          var totalTime = new Date().getTime() - reqStart
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

          tele.record({type, totalTime, runId})

          var cacheEntry = {
            _id: cacheKey,
            type: type,
            timestamp: new Date().getTime(),
            responseTime: totalTime,
            body: body,
            headers: resp.headers,
            statusCode: resp.statusCode,
            runId: runId
          }
          cache.updateOne({_id: cacheKey}, {$set: {cacheEntry}}, {upsert: true}, function (err) {
            if (err) console.error('cache upsert err', err)
            onRes(null, body, resp)
          })
        })
      }, throttleTime)
    })()
  }
}

if (process.env.SIM) {
  apiRequest = function (method, path, postData, onRes) {
    if (typeof postData === 'function') {
      onRes = postData
      postData = null
    }
    postData || (postData = {})
    var mockResponseTime = 0, mockResponse
    var contractsPublicMatch = path.match(/^contracts\/public\/([\d]+)\/$/)
    var type, cacheExpire
    if (contractsPublicMatch) {
      type = 'list_contracts'
      mockResponseTime = 1200
      mockResponse = sampleContractsPage
      if (contractsPublicMatch[1] === '10000002') {
        if (postData.page === 25) {
          mockResponse = [].slice.call(mockResponse, 1)
        }
      }
      else if (postData.page === 5) {
        mockResponse = [].slice.call(mockResponse, 1)
      }
      // On ESI's side, 30 mins
      // 20 hours
      cacheExpire = 10e6*7.2
    }
    var contractsPublicItemsMatch = path.match(/^contracts\/public\/items\/([\d]+)\/$/)
    if (contractsPublicItemsMatch) {
      type = 'contract_items'
      mockResponseTime = 400
      mockResponse = sampleContractItems
      // On ESI's side, 1 hour
      // 90 days
      cacheExpire = 10e8*7.776
    }
    var marketOrdersMatch = path.match(/^markets\/([\d]+)\/orders\/$/)
    if (marketOrdersMatch) {
      type = 'list_orders'
      mockResponseTime = 1000
      mockResponse = sampleOrdersPage
      if (marketOrdersMatch[1] === '10000002') {
        if (postData.page === 220) {
          mockResponse = [].slice.call(mockResponse, 1)
        }
      }
      else if (postData.page === 30) {
        mockResponse = [].slice.call(mockResponse, 1)
      }
      // On ESI's side, 5 mins
      // 20 hours
      cacheExpire = 10e6*7.2
    }
    var typeLookupMatch = path.match(/^universe\/types\/([\d]+)\/$/)
    if (typeLookupMatch) {
      type = 'type_lookup'
      mockResponseTime = 500
      mockResponse = sampleType
      // On ESI's side, 1 day
      // 90 days
      cacheExpire = 10e8*7.776
    }

    var cacheKey = method + '+' + apiBase + path
    if (Object.keys(postData).length) {
      cacheKey += '?' + querystring.stringify(postData)
    }
    // console.log('cacheKey', cacheKey)
    if (!type) {
      throw new Error('unknown API request: ' + cacheKey)
    }
    var resp = {
      statusCode: 200
    }

    cache.findOne({_id: cacheKey, timestamp: {$gt: new Date().getTime() - cacheExpire}}, function (err, doc) {
      if (err) return onRes(err)
      if (false) { //doc) {
        return onRes(null, doc.body, {statusCode: doc.statusCode})
      }
      doRequest()
    })
    function doRequest () {
      const reqStart = new Date()
      // (this would be the http request)
      mockResponseTime += throttleTime
      // (end request)
      setTimeout(function () {
        var totalTime = new Date().getTime() - reqStart
        // console.log('completed', path, 'in', totalTime, 'ms')

        tele.record({type, totalTime, runId})

        var cacheEntry = {
          _id: cacheKey,
          type: type,
          timestamp: new Date().getTime(),
          responseTime: mockResponseTime,
          body: mockResponse,
          headers: null,
          statusCode: resp.statusCode
        }
        cache.updateOne({_id: cacheKey}, {$set: {cacheEntry}}, {upsert: true}, function (err) {
          if (err) return onRes(err)
          onRes(null, mockResponse, resp)
        })
      }, mockResponseTime)
    }
  }
}

function doBackendConnect (connectDone) {
  axarTelemetry({dbName: dbName}, function (err, teleInstance) {
    if (err) return connectDone(err)
    tele = teleInstance
    connectBackend({dbName: dbName}, function (err, _client, _db) {
      if (err) return connectDone(err)
      mongo = _db
      cache = mongo.collection('cache')
      mongoClient = _client
      cache.createIndex({timestamp: -1, type: 1}, function (err) {
        if (err) return connectDone(err)
        connectDone()
      })
    })
  })
}

var rows = [
  csvHeaders
], results = {items: {}}
function doRegionContracts (contractsDone) {
  async.reduce(hub_ids, null, function (_ignore, regionID, done) {
    // type: 1 is item_exchange
    const speedData = [];
    var page = 1;

    async.doWhilst(function (pageCb) {
      // create new progress bar
      const b1 = new cliProgress.SingleBar({
        format: '(MOCK) Searching ' + hubs['' + regionID] + ' page ' + page + ' |' + colors.cyan('{bar}') + '| {percentage}% || {value}/{total} Contracts || Speed: {speed}',
        barCompleteChar: '\u2588',
        barIncompleteChar: '\u2591',
        hideCursor: true
      });

      apiRequest('GET', 'contracts/public/' + regionID + '/', {page}, function (err, body) {
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
              if (contract.type !== 'item_exchange') {
                // only process item exchanges
                b1.increment(1, {
                  speed: getTps() + ' ops/sec'
                })
                return contractDone()
              }
              var items = (body && body.forEach) ? body : [];
              var all_included = items.every(function (item) {
                return item.is_included
              })
              if (all_included) {
                items.forEach(function (item) {
                  var itemKey = '' + item.type_id
                  if (item.is_included) {
                    results.items[itemKey] || (
                      results.items[itemKey] = {
                        soloPrices: [],
                        packagePrices: [],
                        soloRegions: [],
                        packageRegions: [],
                        marketPrices: [],
                        marketRegions: [],
                        marketLiquidity: 0
                      }
                    )
                    if (body.length === 1) {
                      results.items[itemKey].soloPrices.push(contract.price / item.quantity)
                      results.items[itemKey].soloRegions.push(regionID)
                    }
                    else {
                      results.items[itemKey].packagePrices.push(contract.price / item.quantity)
                      results.items[itemKey].packageRegions.push(regionID)
                    }
                  }
                  else {
                    all_included = false
                  }
                })
                if (contract.reward) {
                  //console.error('reward for all included?', regionID, contract, items)
                }
                if (!contract.price) {
                  //console.error('free??', regionID, contract, items)
                }
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
  }, contractsDone)
}

function doRegionOrders (ordersDone) {
  async.reduce(hub_ids, null, function (_ignore, regionID, done) {
    const speedData = [];
    var page = 1;

    // create new progress bar
    const b1 = new cliProgress.SingleBar({
      format: barPrefix + 'Searching ' + hubs['' + regionID] + ' |' + colors.cyan('{bar}') + '| {percentage}% || {value}/{total} x1000 Orders || Speed: {speed}',
      barCompleteChar: '\u2588',
      barIncompleteChar: '\u2591',
      hideCursor: true
    });

    b1.start(orderProgressMax, 0, {
      speed: 'calculating...'
    });

    async.doWhilst(function (pageCb) {
      apiRequest('GET', 'markets/' + regionID + '/orders/', {page, order_type: 'sell'}, function (err, body) {
        if (err) {
          return pageCb(err)
        }
        var fetchLength = body.length || 0;
        if (!fetchLength) return pageCb(null, 0)

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

        body.forEach(function (order) {
          speedData.push(new Date().getTime())
          var itemKey = '' + order.type_id
          results.items[itemKey] || (
            results.items[itemKey] = {
              soloPrices: [],
              packagePrices: [],
              soloRegions: [],
              packageRegions: [],
              marketPrices: [],
              marketRegions: [],
              marketLiquidity: 0
            }
          )
          results.items[itemKey].marketPrices.push(order.price)
          results.items[itemKey].marketRegions.push(regionID)
          results.items[itemKey].marketLiquidity += order.volume_remain
        })
        b1.increment(1, {
          speed: getTps() + ' ops/sec'
        })
        pageCb(null, fetchLength)
      })
    }, function (lastFetchLength, testCb) {
      page++
      testCb(null, lastFetchLength === pageLimit)
    }, function (err, results) {
      b1.stop()
      if (err) return done(err)
      done()
    })
  }, ordersDone)
}

function finalize (err) {
  if (err) throw err
  var numItems = Object.keys(results.items).length
  console.error('Found', numItems, 'unique items.')
  const b1 = new cliProgress.SingleBar({
    format: '(MOCK) Looking up items... |' + colors.yellow('{bar}') + '| {percentage}% || {value}/{total} Items || Speed: {speed}',
    barCompleteChar: '\u2588',
    barIncompleteChar: '\u2591',
    hideCursor: true
  });
  b1.start(numItems, 0, {
    speed: 'calculating...'
  });
  var speedData = []
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
  async.mapValuesLimit(results.items, itemLookupLimit, function (item, typeID, done) {
    db.get('SELECT * FROM invTypes WHERE typeID = ?', [typeID], function (err, invType) {
      if (err) return done(err)
      if (!invType) {
        // console.error('warning: invType not found: ', typeID)
        apiRequest('GET', 'universe/types/' + typeID + '/', function (err, body, resp) {
          if (err) return done(err)
          if (!body || !body.name) {
            console.log('fail', resp.statusCode, resp.headers)
            console.error('warning: invType lookup failed: ', typeID)
            b1.increment(1, {
              speed: getTps() + ' ops/sec'
            })
            return setTimeout(done, itemLookupTimeout)
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
        var maxSoloOccur = 0, modeSoloPrice = null;
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
        var maxPackageOccur = 0, modePackagePrice = null;
        Object.keys(packageOccur).forEach(function (k) {
          if (packageOccur[k] > maxPackageOccur) {
            maxPackageOccur = packageOccur[k]
            modePackagePrice = Number(k)
          }
        })
        var minPackagePrice = item.packagePrices.length ? Math.min.apply(Math, item.packagePrices) : ''
        var maxPackagePrice = item.packagePrices.length ? Math.max.apply(Math, item.packagePrices) : ''

        var totalMarketPrice = item.marketPrices.reduce(function (prev, cur) {
          return prev + cur
        }, 0)
        var meanMarketPrice = item.marketPrices.length ? totalMarketPrice / item.marketPrices.length : ''
        var medianMarketPrice = item.marketPrices.length ? item.marketPrices[0] : ''
        var uniqueMarket = item.marketPrices.filter(onlyUnique);
        if (uniqueMarket.length > 1) {
          var midPoint = Math.floor(uniqueMarket.length / 2)
          medianMarketPrice = uniqueMarket[midPoint]
        }
        var marketOccur = {}
        item.marketPrices.forEach(function (price) {
          var k = price + ''
          if (!marketOccur[k]) marketOccur[k] = 0;
          marketOccur[k]++
        })
        var maxMarketOccur = 0, modeMarketPrice = null;
        Object.keys(marketOccur).forEach(function (k) {
          if (marketOccur[k] > maxMarketOccur) {
            maxMarketOccur = marketOccur[k]
            modeMarketPrice = Number(k)
          }
        })
        var minMarketPrice = item.marketPrices.length ? Math.min.apply(Math, item.marketPrices) : ''
        var maxMarketPrice = item.marketPrices.length ? Math.max.apply(Math, item.marketPrices) : ''

        var minPrice = null, minPriceRegionID, minPriceRegionName
        //console.log('item', item)
        var fromSolo = false, fromMarket = false
        if (minSoloPrice !== '' || minPackagePrice !== '') {
          if (minSoloPrice !== '' && minPackagePrice !== '') {
            if (minSoloPrice <= minPackagePrice) {
              minPrice = minSoloPrice
              fromSolo = true
            }
            else {
              minPrice = minPackagePrice
            }
          }
          else if (minSoloPrice !== '' && minPackagePrice === '') {
            minPrice = minSoloPrice
            fromSolo = true
          }
          else if (minPackagePrice !== '' && minSoloPrice === '') {
            minPrice = minPackagePrice
          }
        }
        if (minMarketPrice !== '') {
          if (minPrice === null || minMarketPrice <= minPrice) {
            minPrice = minMarketPrice
            fromMarket = true
          }
        }
        var minPriceIdx, marketType
        if (fromMarket) {
          minPriceIdx = item.marketPrices.indexOf(minPrice)
          minPriceRegionID = item.marketRegions[minPriceIdx]
          marketType = 'market'
        }
        else if (fromSolo) {
          minPriceIdx = item.soloPrices.indexOf(minPrice)
          minPriceRegionID = item.soloRegions[minPriceIdx]
          marketType = 'solo'
        }
        else {
          minPriceIdx = item.packagePrices.indexOf(minPrice)
          minPriceRegionID = item.packageRegions[minPriceIdx]
          marketType = 'package'
        }
        minPriceRegionName = hubs[minPriceRegionID]
        /*
        console.log('minPriceIdx', minPrice, minPriceIdx)
        console.log('minPriceRegionID', minPriceRegionID)
        console.log('minPriceRegionName', minPriceRegionName)
        */
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
          csvNumber(meanMarketPrice),
          csvNumber(medianMarketPrice),
          csvNumber(modeMarketPrice),
          csvNumber(item.marketLiquidity),
          csvNumber(minMarketPrice),
          csvNumber(maxMarketPrice),
          csvNumber(minPrice),
          marketType,
          minPriceRegionID,
          minPriceRegionName
        ])
        b1.increment(1, {
          speed: getTps() + ' ops/sec'
        })
        speedData.push(new Date().getTime())
        setTimeout(done, itemLookupTimeout)
      }
    })
  }, function (err) {
    if (err) throw err
    b1.stop();
    console.log('data collected! writing CSV...')
    var file = fs.createWriteStream('./output_mock.csv')
    file.once('finish', function () {
      console.log('wrote', './output_mock.csv with', rows.length, 'rows')
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
    tele.close()
    mongoClient.close()
  })
}

async.series([
  doBackendConnect,
  doRegionContracts,
  doRegionOrders
], finalize)
