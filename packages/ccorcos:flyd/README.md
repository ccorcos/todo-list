# Development

Using NPM and Browserify to build a script from require statements:

    browserify build.js -o flyd.js

Then you have to actually go into the script and create a wrapper to assign the variable to `this`.