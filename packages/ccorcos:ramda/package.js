Package.describe({
  name: 'ccorcos:ramda',
  summary: '',
  version: '0.0.1',
  git: 'https://github.com/ccorcos',
});

Package.onUse(function(api) {

  api.versionsFrom('1.0');

  api.add_files([
    'ramda.js',
  ], ['client', 'server']);

})