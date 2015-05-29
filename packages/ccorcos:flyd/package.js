Package.describe({
  name: 'ccorcos:flyd',
  summary: '',
  version: '0.0.2',
  git: 'https://github.com/ccorcos',
});

Package.onUse(function(api) {

  api.versionsFrom('1.0');

  api.add_files([
    'flyd.js',
  ], ['client', 'server']);

})