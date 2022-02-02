module.exports = {
  // meta
  _ns: 'motley',

  'middleware.cors': require('./cors'),

  // register handlers with weights
  'middleware[]': [
    '#middleware.cors'
  ]
}