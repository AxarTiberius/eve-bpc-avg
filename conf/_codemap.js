module.exports = {
  // meta
  _ns: 'motley',
  _folder: 'conf',

  // site overrides
  '@site.port': process.env.PORT || 1339,
  '@site.title': 'EVE Blueprint Copy Average',

  'middleware.buffet{}': {
    watch: false,
    index: 'index.html',
    dot: false
  },
  'middleware.buffet.root{}': {
    globs: 'frontend/build/**/*'
  },
  '@middleware.session': {
    cookie: {
      maxAge: 86400 * 365
    },
    key: 'eve-bpc-avg'
  }
}