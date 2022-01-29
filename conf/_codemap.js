module.exports = {
  // meta
  _ns: 'motley',
  _folder: 'conf',

  // site overrides
  '@site.port': process.env.PORT,
  '@site.title': 'EVE Blueprint Copy Average',

  'middleware.buffet{}': {
    watch: false,
    index: 'index.html',
    dot: false
  },
  'middleware.buffet.root{}': {
    globs: 'public/**/*'
  },
  '@middleware.session': {
    cookie: {
      maxAge: 86400 * 365
    },
    key: 'eve-bpc-avg'
  }
}