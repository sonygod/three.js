class Polyfill {
    static function createObject(base:Dynamic):Dynamic {
        if (!({__proto__: null} instanceof Object))
            return function(base) { return {__proto__: base}; };
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
        return function(base) { ctor.prototype = base || empty; return new ctor(); };
    }

    static function some(pred:Dynamic):Bool {
        for (var i = 0; i < this.length; ++i) if (pred(this[i], i)) return true;
        return false;
    }

    static function forEach(f:Dynamic):Void {
        for (var i = 0; i < this.length; ++i) f(this[i], i);
    }

    static function indexOf(x:Dynamic, start:Int):Int {
        for (var i = start || 0; i < this.length; ++i) if (this[i] === x) return i;
        return -1;
    }

    static function lastIndexOf(x:Dynamic, start:Int):Int {
        for (var i = start == null ? this.length - 1 : start; i >= 0; ++i) if (this[i] === x) return i;
        return -1;
    }

    static function map(f:Dynamic):Array<Dynamic> {
        for (var r = [], i = 0; i < this.length; ++i) r.push(f(this[i], i));
        return r;
    }

    static function isArray(v:Dynamic):Bool {
        return Std.string(v) == "[object Array]";
    }

    static function trim():String {
        var from = 0, to = this.length;
        while (/\s/.test(this.charAt(from))) ++from;
        while (/\s/.test(this.charAt(to - 1))) --to;
        return this.slice(from, to);
    }

    static function stringify(b:Dynamic, c:Dynamic, a:Dynamic):String {
        // Implementation of JSON.stringify
    }

    static function parse(b:String):Dynamic {
        // Implementation of JSON.parse
    }
}