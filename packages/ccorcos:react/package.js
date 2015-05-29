Package.describe({
  name: 'ccorcos:react',
  summary: '',
  version: '0.0.1',
  git: 'https://github.com/ccorcos'
});


Package.on_use(function (api) {
  api.versionsFrom('METEOR@1');
  api.add_files('react.js', 'client');

});