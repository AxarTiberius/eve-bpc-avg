const makeEstimate = require('../make-estimate')

module.exports = function container (get, set) {
  var version = require('../package.json').version
  return get('controller')()
    .options(function (req, res, next) {
      res.json({options: true})
    })
    .post('/estimate', function (req, res, next) {
      makeEstimate(req.body.paste || '', function (err, estimate) {
        if (err) {
          return res.json({
            error: String(err)
          }, 400)
        }
        res.json(estimate)
      })
    })
}