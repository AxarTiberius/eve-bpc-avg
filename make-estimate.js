const csv = require('csv')
var hn = require('human-number')
var assert = require('assert')
const humanNumber = function (num) {
  return String(hn(num, function (n) { return Math.round(Number.parseFloat(n)) })).toLowerCase()
}

var pasteParser = require('./parser');

module.exports = function (pasteText, cb) {
  var parser = csv.parse()
  //console.log('reading ./output.csv...')
  var csvStream = require('fs').createReadStream('./output.csv', {flags: 'r'})
  var i = 0
  var nameIndex = {}
  var headers;
  parser.on('readable', function() {
    let record;
    while ((record = parser.read()) !== null) {
      if (i++ === 0) {
        headers = record
        assert(headers)
        assert.strictEqual(headers.length, 15)
        headers.forEach(function (header, idx) {
          assert(header, idx);
        })
        continue
      }
      assert.strictEqual(record.length, headers.length)
      var item = {}
      headers.forEach(function (header, idx) {
        item[header] = record[idx]
      })
      nameIndex[item.typeName] = item
    }
  });
  parser.on('end', function () {
    //console.log('added', i - 1, 'docs')
    var pasteItems = pasteParser(pasteText)
    var estimate = {
      totalMarketValue: 0,
      itemsProcessed: 0,
      itemsNotFound: 0,
      itemsFound: 0,
      itemsByID: {},
      items: []
    }
    pasteItems.forEach(function (pasteItem) {
      estimate.itemsProcessed++
      var item = nameIndex[pasteItem.name]
      if (!item) {
        estimate.itemsNotFound++
        console.error('warning: Item not found: "' + pasteItem.name + '"')
        return;
      }
      var est
      if (!estimate.itemsByID[item.typeID]) {
        est = estimate.itemsByID[item.typeID] = JSON.parse(JSON.stringify(item))
        Object.keys(est).forEach(function (k) {
          est[k] = est[k].trim()
          if (est[k] === '') {
            est[k] = null
            est[k + '_human'] = ''
          }
          else if (est[k].match(/^[0-9\.]+$/)) {
            est[k] = Number(est[k])
            est[k + '_human'] = humanNumber(est[k])
          }
        })
        est.itemsFound = 0
        est.totalMarketValue = 0
      }
      else {
        est = estimate.itemsByID[item.typeID]
      }
      est.itemsFound += pasteItem.quantity
      estimate.itemsFound += pasteItem.quantity
      est.totalMarketValue += Number(item.minPrice) * pasteItem.quantity
      est.totalMarketValue_human = humanNumber(est.totalMarketValue)
      estimate.totalMarketValue += est.totalMarketValue
    })
    estimate.items = Object.values(estimate.itemsByID).sort(function (a, b) {
      if (a.minPrice > b.minPrice) return -1;
      if (a.minPrice === b.minPrice) return 0;
      return 1;
    })
    delete estimate.itemsByID
    estimate.totalMarketValue_human = humanNumber(estimate.totalMarketValue)
    cb(null, estimate)
  })
  parser.once('error', function(err) {
    //console.error(err.message);
    return cb(err)
  });
  parser.on('end', function() {
    //console.log('ended')
  });
  csvStream.on('end', function () {
    //console.log('tsvStream end')
    parser.end()
  })
  csvStream.pipe(parser)
}
