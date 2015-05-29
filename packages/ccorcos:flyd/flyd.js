var MeteorWrapperObj = {};

(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var flyd = require('flyd');

module.exports = function(dur, s) {
  var scheduled;
  var buffer = [];
  return flyd.stream([s], function(self) {
    buffer.push(s());
    clearTimeout(scheduled);
    scheduled = setTimeout(function() {
      self(buffer);
      buffer = [];
    }, dur);
  });
};

},{"flyd":12}],2:[function(require,module,exports){
var flyd = require('flyd');

module.exports = function(fn, s) {
  return flyd.stream([s], function(self) {
    if (fn(s())) self(s.val);
  });
};

},{"flyd":12}],3:[function(require,module,exports){
var flyd = require('flyd');

module.exports = function(f, s) {
  return flyd.stream([s], function(own) {
    flyd.map(own, f(s()));
  });
};

},{"flyd":12}],4:[function(require,module,exports){
var flyd = require('flyd');

module.exports = flyd.curryN(2, function(targ, fn) {
  var s = flyd.endsOn(targ.end, flyd.stream());
  flyd.map(function(v) { targ(fn(v)); }, s);
  return s;
});

},{"flyd":12}],5:[function(require,module,exports){
var flyd = require('flyd');

module.exports = flyd.curryN(2, function(dur, s) {
  var values = [];
  return flyd.stream([s], function(self) {
    setTimeout(function() {
      self(values = values.slice(1));
    }, dur);
    return (values = values.concat([s()]));
  });
});

},{"flyd":12}],6:[function(require,module,exports){
var flyd = require('flyd');

// Stream bool -> Stream a -> Stream a
module.exports = flyd.curryN(2, function(sBool, sA) {
  return flyd.stream([sA], function(self) {
    if (sBool() !== false) self(sA());
  });
});

},{"flyd":12}],7:[function(require,module,exports){
var flyd = require('flyd');

module.exports = function(f /* , streams */) {
  var streams = Array.prototype.slice.call(arguments, 1);
  var vals = [];
  return flyd.stream(streams, function() {
    for (var i = 0; i < streams.length; ++i) vals[i] = streams[i]();
    return f.apply(null, vals);
  });
};

},{"flyd":12}],8:[function(require,module,exports){
var flyd = require('flyd');

exports.streamProps = function(from) {
  var to = {};
  for (var key in from) {
    if (from.hasOwnProperty(key)) {
      to[key] = flyd.stream(from[key]);
    }
  }
  return to;
};

var extractProps = exports.extractProps = function(obj) {
  var newObj = {};
  for (var key in obj) {
    if (obj.hasOwnProperty(key)) {
      newObj[key] = flyd.isStream(obj[key]) ? obj[key]() : obj[key];
    }
  }
  return newObj;
};

exports.stream = function(obj) {
  var streams = Object.keys(obj).map(function(key) { return obj[key]; });
  return flyd.stream(streams, function() {
    return extractProps(obj);
  });
};

},{"flyd":12}],9:[function(require,module,exports){
var flyd = require('flyd');

module.exports = flyd.curryN(2, function(s1, s2) {
  return flyd.stream([s1], function() {
    return s2();
  });
});

},{"flyd":12}],10:[function(require,module,exports){
var flyd = require('flyd');

module.exports = flyd.curryN(2, function(pairs, acc) {
  var streams = pairs.map(function(p) { return p[0]; });
  var fns = pairs.map(function(p) { return p[1]; });
  return flyd.immediate(flyd.stream(streams, function(self, changed) {
    if (changed.length > 0) {
      var idx = streams.indexOf(changed[0]);
      acc = fns[idx](acc, changed[0]());
    }
    return acc;
  }));
});

},{"flyd":12}],11:[function(require,module,exports){
var flyd = require('flyd');

module.exports = function(src, term) {
  return flyd.endsOn(flyd.merge(term, src.end), flyd.stream([src], function(self) {
    self(src());
  }));
};

},{"flyd":12}],12:[function(require,module,exports){
(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([], factory); // AMD. Register as an anonymous module.
  } else if (typeof exports === 'object') {
    module.exports = factory(); // NodeJS
  } else { // Browser globals (root is window)
    root.flyd = factory();
  }
}(this, function () {

'use strict';

function isFunction(obj) {
  return !!(obj && obj.constructor && obj.call && obj.apply);
}

function notUndef(v) {
  return v !== undefined;
}

var toUpdate = [];
var inStream;

function map(f, s) {
  return stream([s], function(self) { self(f(s())); });
}

function boundMap(f) { return map(f, this); }

var scan = curryN(3, function(f, acc, s) {
  var ns = stream([s], function() {
    return (acc = f(acc, s()));
  });
  if (!ns.hasVal) ns(acc);
  return ns;
});

var merge = curryN(2, function(s1, s2) {
  var s = immediate(stream([s1, s2], function(n, changed) {
    return changed[0] ? changed[0]()
         : s1.hasVal  ? s1()
                      : s2();
  }));
  endsOn(stream([s1.end, s2.end], function(self, changed) {
    return true;
  }), s);
  return s;
});

function ap(s2) {
  var s1 = this;
  return stream([s1, s2], function() { return s1()(s2()); });
}

function initialDepsNotMet(stream) {
  stream.depsMet = stream.deps.every(function(s) {
    return s.hasVal;
  });
  return !stream.depsMet;
}

function updateStream(s) {
  if ((s.depsMet !== true && initialDepsNotMet(s)) ||
      (s.end !== undefined && s.end.val === true)) return;
  inStream = s;
  var returnVal = s.fn(s, s.depsChanged);
  if (returnVal !== undefined) {
    s(returnVal);
  }
  inStream = undefined;
  while (s.depsChanged.length > 0) s.depsChanged.shift();
}

var order = [];
var orderNextIdx = -1;

function findDeps(s) {
  var i, listeners = s.listeners;
  if (s.queued === false) {
    s.queued = true;
    for (i = 0; i < listeners.length; ++i) {
      findDeps(listeners[i]);
    }
    order[++orderNextIdx] = s;
  }
}

function updateDeps(s) {
  var i, list, listeners = s.listeners;
  for (i = 0; i < listeners.length; ++i) {
    list = listeners[i];
    if (list.end === s) {
      endStream(list);
    } else {
      list.depsChanged.push(s);
      findDeps(list);
    }
  }
  for (i = orderNextIdx; i >= 0; --i) {
    if (order[i].depsChanged !== undefined && order[i].depsChanged.length > 0) {
      updateStream(order[i]);
    }
    order[i].queued = false;
  }
  orderNextIdx = -1;
}

function flushUpdate() {
  while (toUpdate.length > 0) updateDeps(toUpdate.shift());
}

function isStream(stream) {
  return isFunction(stream) && 'hasVal' in stream;
}

function streamToString() {
  return 'stream(' + this.val + ')';
}

function createStream() {
  function s(n) {
    var i, list;
    if (arguments.length === 0) {
      return s.val;
    } else {
      if (n !== undefined && n !== null && isFunction(n.then)) {
        n.then(s);
        return;
      }
      s.val = n;
      s.hasVal = true;
      if (inStream === undefined) {
        updateDeps(s);
        if (toUpdate.length !== 0) flushUpdate();
      } else if (inStream === s) {
        for (i = 0; i < s.listeners.length; ++i) {
          list = s.listeners[i];
          if (list.end !== s) list.depsChanged.push(s);
          else endStream(list);
        }
      } else {
        toUpdate.push(s);
      }
      return s;
    }
  }
  s.hasVal = false;
  s.val = undefined;
  s.listeners = [];
  s.queued = false;
  s.end = undefined;

  s.map = boundMap;
  s.ap = ap;
  s.of = stream;
  s.toString = streamToString;

  return s;
}

function createDependentStream(deps, fn) {
  var i, s = createStream();
  s.fn = fn;
  s.deps = deps;
  s.depsMet = false;
  s.depsChanged = [];
  for (i = 0; i < deps.length; ++i) {
    deps[i].listeners.push(s);
  }
  return s;
}

function immediate(s) {
  if (s.depsMet === false) {
    s.depsMet = true;
    updateStream(s);
    if (toUpdate.length !== 0) flushUpdate();
  }
  return s;
}

function removeListener(s, listeners) {
  var idx = listeners.indexOf(s);
  listeners[idx] = listeners[listeners.length - 1];
  listeners.length--;
}

function detachDeps(s) {
  for (var i = 0; i < s.deps.length; ++i) {
    removeListener(s, s.deps[i].listeners);
  }
  s.deps.length = 0;
}

function endStream(s) {
  if (s.deps !== undefined) detachDeps(s);
  if (s.end !== undefined) detachDeps(s.end);
}

function endsOn(endS, s) {
  detachDeps(s.end);
  endS.listeners.push(s.end);
  s.end.deps.push(endS);
  return s;
}

function stream(arg, fn) {
  var s, deps;
  var endStream = createDependentStream([], function() { return true; });
  if (arguments.length > 1) {
    deps = arg.filter(notUndef);
    s = createDependentStream(deps, fn);
    s.end = endStream;
    endStream.listeners.push(s);
    var depEndStreams = deps.map(function(d) { return d.end; }).filter(notUndef);
    endsOn(createDependentStream(depEndStreams, function() { return true; }, true), s);
    updateStream(s);
    if (toUpdate.length !== 0) flushUpdate();
  } else {
    s = createStream();
    s.end = endStream;
    endStream.listeners.push(s);
    if (arguments.length === 1) s(arg);
  }
  return s;
}

var transduce = curryN(2, function(xform, source) {
  xform = xform(new StreamTransformer());
  return stream([source], function(self) {
    var res = xform['@@transducer/step'](undefined, source());
    if (res && res['@@transducer/reduced'] === true) {
      self.end(true);
      return res['@@transducer/value'];
    } else {
      return res;
    }
  });
});

function StreamTransformer() { }
StreamTransformer.prototype['@@transducer/init'] = function() { };
StreamTransformer.prototype['@@transducer/result'] = function() { };
StreamTransformer.prototype['@@transducer/step'] = function(s, v) { return v; };

// Own curry implementation snatched from Ramda
// Figure out something nicer later on
var _ = {placeholder: true};

// Detect both own and Ramda placeholder
function isPlaceholder(p) {
  return p === _ || (p && p.ramda === 'placeholder');
}

function toArray(arg) {
  var arr = [];
  for (var i = 0; i < arg.length; ++i) {
    arr[i] = arg[i];
  }
  return arr;
}

// Modified versions of arity and curryN from Ramda
function ofArity(n, fn) {
  if (arguments.length === 1) {
    return ofArity.bind(undefined, n);
  }
  switch (n) {
  case 0:
    return function () {
      return fn.apply(this, arguments);
    };
  case 1:
    return function (a0) {
      void a0;
      return fn.apply(this, arguments);
    };
  case 2:
    return function (a0, a1) {
      void a1;
      return fn.apply(this, arguments);
    };
  case 3:
    return function (a0, a1, a2) {
      void a2;
      return fn.apply(this, arguments);
    };
  case 4:
    return function (a0, a1, a2, a3) {
      void a3;
      return fn.apply(this, arguments);
    };
  case 5:
    return function (a0, a1, a2, a3, a4) {
      void a4;
      return fn.apply(this, arguments);
    };
  case 6:
    return function (a0, a1, a2, a3, a4, a5) {
      void a5;
      return fn.apply(this, arguments);
    };
  case 7:
    return function (a0, a1, a2, a3, a4, a5, a6) {
      void a6;
      return fn.apply(this, arguments);
    };
  case 8:
    return function (a0, a1, a2, a3, a4, a5, a6, a7) {
      void a7;
      return fn.apply(this, arguments);
    };
  case 9:
    return function (a0, a1, a2, a3, a4, a5, a6, a7, a8) {
      void a8;
      return fn.apply(this, arguments);
    };
  case 10:
    return function (a0, a1, a2, a3, a4, a5, a6, a7, a8, a9) {
      void a9;
      return fn.apply(this, arguments);
    };
  default:
    throw new Error('First argument to arity must be a non-negative integer no greater than ten');
  }
}

function curryN(length, fn) {
  return ofArity(length, function () {
    var n = arguments.length;
    var shortfall = length - n;
    var idx = n;
    while (--idx >= 0) {
      if (isPlaceholder(arguments[idx])) {
        shortfall += 1;
      }
    }
    if (shortfall <= 0) {
      return fn.apply(this, arguments);
    } else {
      var initialArgs = toArray(arguments);
      return curryN(shortfall, function () {
        var currentArgs = toArray(arguments);
        var combinedArgs = [];
        var idx = -1;
        while (++idx < n) {
          var val = initialArgs[idx];
          combinedArgs[idx] = isPlaceholder(val) ? currentArgs.shift() : val;
        }
        return fn.apply(this, combinedArgs.concat(currentArgs));
      });
    }
  });
}


return {
  stream: stream,
  isStream: isStream,
  transduce: transduce,
  merge: merge,
  reduce: scan, // Legacy
  scan: scan,
  endsOn: endsOn,
  map: curryN(2, map),
  curryN: curryN,
  _: _,
  immediate: immediate,
};

}));

},{}],13:[function(require,module,exports){
flyd = require('flyd')
flyd.filter = require('flyd-filter')
flyd.lift = require('flyd-lift')
flyd.flatmap = require('flyd-flatmap')
// flyd.switchlatest = require('flyd-switchlatest')
flyd.keepwhen = require('flyd-keepwhen')
flyd.obj = require('flyd-obj')
flyd.sampleon = require('flyd-sampleon')
flyd.scanmerge = require('flyd-scanmerge')
flyd.takeuntil = require('flyd-takeuntil')
flyd.forwardto = require('flyd-forwardto')
flyd.aftersilence = require('flyd-aftersilence')
// flyd.every = require('flyd-every')
flyd.inlast = require('flyd-inlast')
MeteorWrapperObj.flyd = flyd;

},{"flyd":12,"flyd-aftersilence":1,"flyd-filter":2,"flyd-flatmap":3,"flyd-forwardto":4,"flyd-inlast":5,"flyd-keepwhen":6,"flyd-lift":7,"flyd-obj":8,"flyd-sampleon":9,"flyd-scanmerge":10,"flyd-takeuntil":11}]},{},[13]);

this.flyd = MeteorWrapperObj.flyd;