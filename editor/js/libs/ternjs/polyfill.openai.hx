// Shims to fill in enough of ECMAScript 5 to make Tern run.

// Object.create
if (!Object.create) {
    Object.create = function(base) {
        if (!({__proto__: null} instanceof Object)) {
            return function(base) {
                return {__proto__: base};
            };
        }
        function ctor() {}
        var frame = js.Browser.document.body.appendChild(js.Browser.document.createElement("iframe"));
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
    }();
}

// Array methods
var AP = js.Array.prototype;

AP.some = AP.some || function(pred) {
    for (i in this) if (pred(this[i], i)) return true;
    return false;
};

AP.forEach = AP.forEach || function(f) {
    for (i in this) f(this[i], i);
};

AP.indexOf = AP.indexOf || function(x, start) {
    for (i in this) if (this[i] === x) return i;
    return -1;
};

AP.lastIndexOf = AP.lastIndexOf || function(x, start) {
    for (var i = start == null ? this.length - 1 : start; i >= 0; --i) if (this[i] === x) return i;
    return -1;
};

AP.map = AP.map || function(f) {
    var r = [];
    for (i in this) r.push(f(this[i], i));
    return r;
};

js.Array.isArray = js.Array.isArray || function(v) {
    return js.Type.typeof(v) == "array";
};

js.String.prototype.trim = js.String.prototype.trim || function() {
    var from = 0, to = this.length;
    while (/\s/.test(this.charAt(from))) ++from;
    while (/\s/.test(this.charAt(to - 1))) --to;
    return this.slice(from, to);
};

// JSON Polyfill
if (!js.Json) (function() {
    // ... (rest of the JSON polyfill code)
})();

// ... (other code)