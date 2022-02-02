module.exports = function container (get, set) {
  return function handler (req, res, next) {
    if (process.env.NODE_ENV !== 'production') {
      res.header(
        'Access-Control-Allow-Origin',
        'http://localhost:3000'
      )
    }
    res.header(
      'Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept'
    )
    res.header('Access-Control-Allow-Credentials', true)
    next()
  }
}
