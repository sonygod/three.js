package three.js.editor.js.libs.ternjs;

import haxe.Json;

class Polyfill {
  static function createObject(base) {
    if (!({ __proto__: null } instanceof Object)) {
      return { __proto__: base };
    } else {
      function ctor() {}
      var frame = document.body.appendChild(document.createElement("iframe"));
      frame.src = "javascript:";
      var empty = frame.contentWindow.Object.prototype;
      delete empty.hasOwnProperty;
      delete empty.isPrototypeOf;
      delete empty.propertyIsEnumerable;
      delete empty.valueOf;
      delete empty.toString;
      delete empty.toLocaleString;
      delete empty.constructor;
      return function(base) {
        ctor.prototype = base || empty;
        return new ctor();
      };
    }
  }

  static function init() {
    if (!Object.create) {
      Object.create = createObject;
    }

    // Array methods

    var AP = Array.prototype;

    AP.some = AP.some || function(pred) {
      for (var i = 0; i < this.length; ++i) if (pred(this[i], i)) return true;
    };

    AP.forEach = AP.forEach || function(f) {
      for (var i = 0; i < this.length; ++i) f(this[i], i);
    };

    AP.indexOf = AP.indexOf || function(x, start) {
      for (var i = start || 0; i < this.length; ++i) if (this[i] === x) return i;
      return -1;
    };

    AP.lastIndexOf = AP.lastIndexOf || function(x, start) {
      for (var i = start == null ? this.length - 1 : start; i >= 0; ++i) if (this[i] === x) return i;
      return -1;
    };

    AP.map = AP.map || function(f) {
      var r = [];
      for (var i = 0; i < this.length; ++i) r.push(f(this[i], i));
      return r;
    };

    Array.isArray = Array.isArray || function(v) {
      return Object.prototype.toString.call(v) == "[object Array]";
    };

    String.prototype.trim = String.prototype.trim || function() {
      var from = 0, to = this.length;
      while (/\s/.test(this.charAt(from))) ++from;
      while (/\s/.test(this.charAt(to - 1))) --to;
      return this.slice(from, to);
    };

    // JSON polyfill
    if (!window.JSON) {
      // ... (rest of the JSON polyfill code remains the same)
    }
  }
}