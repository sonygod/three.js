package js.signals;

class SignalBinding {
    public var _listener: Dynamic;
    public var _isOnce: Bool;
    public var context: Dynamic;
    public var _signal: Signal;
    public var _priority: Int;

    public function new(a: Signal, b: Dynamic, c: Bool, d: Dynamic, e: Int) {
        this._listener = b;
        this._isOnce = c;
        this.context = d;
        this._signal = a;
        this._priority = e != null ? e : 0;
    }

    public var active: Bool = true;
    public var params: Array<Dynamic>;

    public function execute(a: Array<Dynamic>): Dynamic {
        var b: Dynamic;
        if (this.active && this._listener != null) {
            if (this.params != null) {
                a = this.params.concat(a);
            }
            b = this._listener.apply(this.context, a);
            if (this._isOnce) {
                this.detach();
            }
        }
        return b;
    }

    public function detach(): Dynamic {
        if (this.isBound()) {
            return this._signal.remove(this._listener, this.context);
        }
        return null;
    }

    public function isBound(): Bool {
        return this._signal != null && this._listener != null;
    }

    public function isOnce(): Bool {
        return this._isOnce;
    }

    public function getListener(): Dynamic {
        return this._listener;
    }

    public function getSignal(): Signal {
        return this._signal;
    }

    public function _destroy(): Void {
        this._signal = null;
        this._listener = null;
        this.context = null;
    }

    public override function toString(): String {
        return "[SignalBinding isOnce:" + this._isOnce + ", isBound:" + this.isBound() + ", active:" + this.active + "]";
    }
}

class Signal {
    public var _bindings: Array<SignalBinding> = [];
    public var _prevParams: Array<Dynamic>;
    public var dispatch: Dynamic;

    public function new() {
        this._prevParams = null;
        var a: Signal = this;
        this.dispatch = function(...args: Array<Dynamic>) {
            return Signal.prototype.dispatch.apply(a, args);
        }
    }

    public static var VERSION: String = "1.0.0";
    public var memorize: Bool = false;
    public var _shouldPropagate: Bool = true;
    public var active: Bool = true;

    public function _registerListener(a: Dynamic, b: Bool, c: Dynamic, d: Int): SignalBinding {
        var e = this._indexOfListener(a, c);
        if (e !== -1) {
            if (a = this._bindings[e], a.isOnce() !== b) {
                throw Error("You cannot add" + (b ? "" : "Once") + "() then add" + (!b ? "" : "Once") + "() the same listener without removing the relationship first.");
            }
        } else {
            a = new SignalBinding(this, a, b, c, d);
            this._addBinding(a);
            if (this.memorize && this._prevParams != null) {
                a.execute(this._prevParams);
            }
        }
        return a;
    }

    public function _addBinding(a: SignalBinding): Void {
        var b = this._bindings.length;
        do {
            b--;
        } while (this._bindings[b] != null && a._priority <= this._bindings[b]._priority);
        this._bindings.splice(b + 1, 0, a);
    }

    public function _indexOfListener(a: Dynamic, b: Dynamic): Int {
        for (var c = this._bindings.length, d; c--;) {
            if (d = this._bindings[c], d._listener === a && d.context === b) {
                return c;
            }
        }
        return -1;
    }

    public function has(a: Dynamic, b: Dynamic): Bool {
        return this._indexOfListener(a, b) !== -1;
    }

    public function add(a: Dynamic, b: Dynamic, c: Int): SignalBinding {
        if (typeof(a) !== "function") {
            throw Error("listener is a required param of {fn}() and should be a Function.".replace("{fn}", "add"));
        }
        return this._registerListener(a, false, b, c);
    }

    public function addOnce(a: Dynamic, b: Dynamic, c: Int): SignalBinding {
        if (typeof(a) !== "function") {
            throw Error("listener is a required param of {fn}() and should be a Function.".replace("{fn}", "addOnce"));
        }
        return this._registerListener(a, true, b, c);
    }

    public function remove(a: Dynamic, b: Dynamic): Dynamic {
        if (typeof(a) !== "function") {
            throw Error("listener is a required param of {fn}() and should be a Function.".replace("{fn}", "remove"));
        }
        var c = this._indexOfListener(a, b);
        if (c !== -1) {
            this._bindings[c]._destroy();
            this._bindings.splice(c, 1);
        }
        return a;
    }

    public function removeAll(): Void {
        for (var a = this._bindings.length; a--;) {
            this._bindings[a]._destroy();
        }
        this._bindings.length = 0;
    }

    public function getNumListeners(): Int {
        return this._bindings.length;
    }

    public function halt(): Void {
        this._shouldPropagate = false;
    }

    public function dispatch(a: Array<Dynamic>): Void {
        if (this.active) {
            var b = Array.prototype.slice.call(arguments);
            var c = this._bindings.length;
            var d;
            if (this.memorize) {
                this._prevParams = b;
            }
            if (c > 0) {
                d = this._bindings.slice();
                this._shouldPropagate = true;
                do {
                    c--;
                } while (d[c] != null && this._shouldPropagate && d[c].execute(b) !== false);
            }
        }
    }

    public function forget(): Void {
        this._prevParams = null;
    }

    public function dispose(): Void {
        this.removeAll();
        this._bindings = null;
        this._prevParams = null;
    }

    public override function toString(): String {
        return "[Signal active:" + this.active + " numListeners:" + this.getNumListeners() + "]";
    }
}