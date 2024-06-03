class Polyfill {
    static function main() {
        if (js.Boot.__instanceof(null, js.Object)) {
            js.Object.create = function(base:Dynamic) {
                return js.__Boot_Haxe_dynamic_Object_Impl_.create(base);
            };
        } else {
            js.Object.create = function(base:Dynamic) {
                var ctor = function() {};
                ctor.prototype = base || {};
                return new ctor();
            };
        }

        var AP = js.Boot.__cast(Array.prototype, js.Array<Dynamic>);

        AP.some = function(pred:js.Function) {
            var _g = 0;
            var _g1 = this.length;
            while (_g < _g1) {
                var i = _g++;
                if (Reflect.callMethod(pred, this, [this[i], i])) {
                    return true;
                }
            }
            return false;
        };

        AP.forEach = function(f:js.Function) {
            var _g = 0;
            var _g1 = this.length;
            while (_g < _g1) {
                var i = _g++;
                Reflect.callMethod(f, this, [this[i], i]);
            }
        };

        AP.indexOf = function(x:Dynamic, start:Int = 0) {
            var _g = start;
            var _g1 = this.length;
            while (_g < _g1) {
                var i = _g++;
                if (this[i] === x) {
                    return i;
                }
            }
            return -1;
        };

        AP.lastIndexOf = function(x:Dynamic, start:Int = null) {
            var i = start == null ? this.length - 1 : start;
            while (i >= 0) {
                if (this[i] === x) {
                    return i;
                }
                i--;
            }
            return -1;
        };

        AP.map = function(f:js.Function) {
            var r = [];
            var _g = 0;
            var _g1 = this.length;
            while (_g < _g1) {
                var i = _g++;
                r.push(Reflect.callMethod(f, this, [this[i], i]));
            }
            return r;
        };

        Array.isArray = function(v:Dynamic) {
            return js.Boot.instanceof(v, Array);
        };

        String.prototype.trim = function() {
            var from = 0;
            var to = this.length;
            while (/\s/.test(this.charAt(from))) {
                from++;
            }
            while (/\s/.test(this.charAt(to - 1))) {
                to--;
            }
            return this.slice(from, to);
        };
    }
}