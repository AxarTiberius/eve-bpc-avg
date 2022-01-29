const csv = require('csv')
var hn = require('human-number')
const humanNumber = function (num) {
  return hn(num, function (n) { return Math.round(Number.parseFloat(n)) })
}

module.exports = function (pasteText, cb) {
  var parser = csv.parse()
  //console.log('reading ./output.csv...')
  var csvStream = require('fs').createReadStream('./output.csv', {flags: 'r'})
  var i = 0
  var nameIndex = {}
  parser.on('readable', function() {
    let record;
    while ((record = parser.read()) !== null) {
      //console.log('record', record)
      if (i++ === 0) continue;
      nameIndex[record[1]] = record
    }
  });
  parser.on('end', function () {
    //console.log('added', i - 1, 'docs')
    var lines = pasteText.split(/\r?\n/)
    lines = lines.filter(function (line) {
      line = line.trim()
      return line.length > 0
    })
    var estimate = {
      totalAverageWorth: 0,
      itemsProcessed: 0,
      itemsNotFound: 0,
      itemsFound: 0,
      items: {}
    }
    lines.forEach(function (line) {
      var line_vars = line.split('  ')
      if (!line_vars || !line_vars.length) return;
      var name = line_vars[0].trim()
      if (!name || !name.length) return;
      estimate.itemsProcessed++
      var item = nameIndex[name]
      if (!item) {
        estimate.itemsNotFound++
        console.error('Item not found: "' + name + '"')
        return;
      }
      estimate.itemsFound++
      estimate.totalAverageWorth += Number(item[3])
      if (!estimate.items[name]) {
        estimate.items[name] = {
          typeID: Number(item[0].trim()),
          name: name,
          contracts: Number(item[2].trim()),
          meanPrice: Number(item[3].trim()),
          medianPrice: Number(item[4].trim()),
          modePrice: Number(item[5].trim()),
          itemsFound: 0
        }
      }
      estimate.items[name].itemsFound++
    })
    estimateItemLookup = estimate.items;
    estimate.items = Object.keys(estimateItemLookup).map(function (name) {
      estimateItemLookup[name].meanPrice_human = humanNumber(estimateItemLookup[name].meanPrice) + ' ISK'
      estimateItemLookup[name].medianPrice_human = humanNumber(estimateItemLookup[name].medianPrice) + ' ISK'
      estimateItemLookup[name].modePrice_human = humanNumber(estimateItemLookup[name].modePrice) + ' ISK'
      return estimateItemLookup[name]
    })
    estimate.items.sort(function (a, b) {
      if (a.meanPrice > b.meanPrice) return -1;
      if (a.meanPrice === b.meanPrice) return 0;
      return 1;
    })
    estimate.totalAverageWorth_human = humanNumber(estimate.totalAverageWorth) + ' ISK'
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
