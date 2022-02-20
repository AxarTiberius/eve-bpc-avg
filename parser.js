var parser = function (pasteText) {
  var result = []
  var lines = pasteText.split(/\n/g)
  lines.forEach(function (line, idx) {
    line = line.trim()
    if (line === '') return;
    // try to find quantity on the right bound
    var name = line.match(/^([\w"'\- ]+?) (?: |[\d,\.])/)
    if (!name) {
      // fall back to no quantity
      name = line.match(/^([\w"'\- ]+)/)
    }
    if (name) {
      name = name[1]
    }
    else {
      // fall back to split by double space
      name = line.split('  ')[0]
    }
    // parse for numbers and units
    var numbers = line.match(/([\d,\.]+)(?: (m3|ISK))?/g)
    var quantity = 1, volume, price;
    if (numbers && numbers.length) {
      var parsedNumber
      for (var idx = 0; idx < numbers.length; idx++) {
        if (parsedNumber = numbers[idx].match(/([\d,\.]+)(?: (m3|ISK))?$/)) {
          var value = parseFloat(parsedNumber[1].replace(/[,]/g, ''), 10)
          if (parsedNumber[2] === 'm3') {
            volume = value
          }
          else if (parsedNumber[2] === 'ISK') {
            price = value
          }
          else {
            quantity = value
          }
        }
      }
    }
    var item = {
      name: name,
      quantity: quantity,
      volume: volume,
      price: price
    }
    console.log(line, item)
    result.push(item)
  })
  return result
}

module.exports = parser;
