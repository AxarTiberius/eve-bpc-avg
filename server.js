var motley = require('motley')
var dotenv = require('dotenv')
dotenv.config()

try {
  var app = motley({
    _ns: 'motley',
    _maps: [
      require('./_codemap'),
      require('motley-buffet')
    ]
  })
}
catch (err) {
  exit(err)
}

function exit (err) {
  console.error(err)
  console.error(err.stack)
  process.exit(1)
}

app.listen(function (err) {
  if (err) exit(err)
  var closed = false
  function onExit () {
    if (closed) return
    closed = true
    app.close(function (err) {
      if (err) exit(err)
    })
  }
  process.once('SIGINT', onExit)
  process.once('SIGTERM', onExit)
})