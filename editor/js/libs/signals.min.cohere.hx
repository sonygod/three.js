package js.signals;

class SignalBinding {
    var _listener:Dynamic;
    var _isOnce:Bool;
    var context:Dynamic;
    var _signal:Signal;
    var _priority:Int;

    public function new(_listener:Dynamic, _isOnce:Bool, ?context:Dynamic, ?_signal:Signal, ?_priority:Int) {
        this._listener = _listener;
        this._isOnce = _isOnce;
        this.context = context;
        this._signal = _signal;
        this._priority = _priority ?? 0;
    }

    public function active(default:Bool):Bool;
    public function active(?value:Bool):Bool;
    public function active(?value:Bool):Bool {
        if (value != null) {
            return value;
        }
        return true;
    }

    public var params:Array<Dynamic>;

    public function execute(arr:Array<Dynamic>):Dynamic {
        if (active()) {
            var args = params != null ? params.concat(arr) : arr;
            var result = _listener.apply(context, args);
            if (_isOnce) {
                detach();
            }
            return result;
        }
        return null;
    }

    public function detach():Bool {
        if (isBound()) {
            _signal.remove(_listener, context);
            return true;
        }
        return false;
    }

    public function isBound():Bool {
        return _signal != null && _listener != null;
    }

    public function isOnce():Bool {
        return _isOnce;
    }

    public function getListener():Dynamic {
        return _listener;
    }

    public function getSignal():Signal {
        return _signal;
    }

    public function _destroy() {
        _signal = null;
        _listener = null;
        context = null;
    }

    public function toString():String {
        return "[SignalBinding isOnce:" + _isOnce + ", isBound:" + isBound() + ", active:" + active() + "]";
    }
}

class Signal {
    public var _bindings:Array<SignalBinding>;
    public var _prevParams:Array<Dynamic>;
    public var dispatch:Dynamic;

    public function new() {
        _bindings = [];
        _prevParams = [];
        this.dispatch = function() {
            return dispatch.apply(this, arguments);
        };
    }

    public var VERSION:String = "1.0.0";
    public var memorize:Bool;
    public var _shouldPropagate:Bool;
    public var active:Bool;

    function _registerListener(_listener:Dynamic, _isOnce:Bool, ?context:Dynamic, ?_priority:Int):SignalBinding {
        var index = _indexOfListener(_listener, context);
        if (index != -1) {
            var binding = _bindings[index];
            if (binding.isOnce() != _isOnce) {
                throw "You cannot add" + (_isOnce ? "" : "Once") + "() then add" + (!_isOnce ? "" : "Once") + "() the same listener without removing the relationship first.";
            }
        } else {
            binding = new SignalBinding(_listener, _isOnce, context, this, _priority);
            _addBinding(binding);
        }
        if (memorize) {
            if (_prevParams != null) {
                binding.execute(_prevParams);
            }
        }
        return binding;
    }

    function _addBinding(binding:SignalBinding) {
        var length = _bindings.length;
        var i = length;
        while (i > 0 && binding._priority <= _bindings[i - 1]._priority) {
            --i;
        }
        _bindings.insert(i, binding);
    }

    function _indexOfListener(_listener:Dynamic, ?context:Dynamic):Int {
        var length = _bindings.length;
        for (i in 0...length) {
            var currentBinding = _bindings[i];
            if (currentBinding._listener == _listener && currentBinding.context == context) {
                return i;
            }
        }
        return -1;
    }

    public function has(_listener:Dynamic, ?context:Dynamic):Bool {
        return _indexOfListener(_listener, context) != -1;
    }

    public function add(_listener:Dynamic, ?context:Dynamic, ?_priority:Int):SignalBinding {
        if (typeof(_listener) != "function") {
            throw "listener is a required param of {fn}() and should be a Function.".replace("{fn}", "add");
        }
        return _registerListener(_listener, false, context, _priority);
    }

    public function addOnce(_listener:Dynamic, ?context:Dynamic, ?_priority:Int):SignalBinding {
        if (typeof(_listener) != "function") {
            throw "listener is a required param of {fn}() and should be a Function.".replace("{fn}", "addOnce");
        }
        return _registerListener(_listener, true, context, _priority);
    }

    public function remove(_listener:Dynamic, ?context:Dynamic):Dynamic {
        if (typeof(_listener) != "function") {
            throw "listener is a required param of {fn}() and should be a Function.".replace("{fn}", "remove");
        }
        var index = _indexOfListener(_listener, context);
        if (index != -1) {
            var binding = _bindings[index];
            binding._destroy();
            _bindings.splice(index, 1);
            return _listener;
        }
        return null;
    }

    public function removeAll() {
        var length = _bindings.length;
        for (i in 0...length) {
            _bindings[i]._destroy();
        }
        _bindings.length = 0;
    }

    public function getNumListeners():Int {
        return _bindings.length;
    }

    public function halt() {
        _shouldPropagate = false;
    }

    public function dispatch(arr:Array<Dynamic>) {
        if (active) {
            var args = Array.from(arr);
            var length = _bindings.length;
            if (memorize) {
                _prevParams = args;
            }
            if (length > 0) {
                _shouldPropagate = true;
                var bindings = _bindings.slice();
                for (i in 0...length) {
                    if (_shouldPropagate) {
                        bindings[i].execute(args);
                    }
                }
            }
        }
    }

    public function forget() {
        _prevParams = [];
    }

    public function dispose() {
        removeAll();
        _bindings = [];
        _prevParams = [];
    }

    public function toString():String {
        return "[Signal active:" + active + " numListeners:" + getNumListeners() + "]";
    }
}

class Signals {
    public static function Signal():Signal {
        return new Signal();
    }
}

if (typeof(window) != "undefined") {
    window.js = window.js ?? {};
    window.js.signals = Signals;
}