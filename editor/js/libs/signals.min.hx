Here is the converted Haxe code:
```
package js.signals;

/**
 * JS Signals
 * Released under the MIT license
 * Author: Miller Medeiros
 * Version: 1.0.0 - Build: 268 (2012/11/29 05:48 PM)
 */

import js.Lib;

class SignalBinding {
    public var _listener:Dynamic;
    public var _isOnce:Bool;
    public var context:Dynamic;
    public var _signal:Signal;
    public var _priority:Int;
    public var active:Bool;
    public var params:Array<Dynamic>;

    public function new(signal:Signal, listener:Dynamic, isOnce:Bool, context:Dynamic, priority:Int = 0) {
        _listener = listener;
        _isOnce = isOnce;
        this.context = context;
        _signal = signal;
        _priority = priority;
        active = true;
        params = null;
    }

    public function execute(args:Array<Dynamic>):Dynamic {
        if (active && _listener != null) {
            var newArgs:Array<Dynamic> = params != null ? params.concat(args) : args;
            var result:Dynamic = _listener.apply(context, newArgs);
            if (_isOnce) detach();
            return result;
        }
        return null;
    }

    public function detach():Dynamic {
        if (isBound()) {
            _signal.remove(_listener, context);
        }
        return null;
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

    public function toString():String {
        return "[SignalBinding isOnce:" + _isOnce + ", isBound:" + isBound() + ", active:" + active + "]";
    }

    public function _destroy() {
        _signal = null;
        _listener = null;
        context = null;
    }
}

class Signal {
    public var _bindings:Array<SignalBinding>;
    public var _prevParams:Array<Dynamic>;
    public var VERSION:String;
    public var memorize:Bool;
    public var _shouldPropagate:Bool;
    public var active:Bool;

    public function new() {
        _bindings = new Array<SignalBinding>();
        _prevParams = null;
        VERSION = "1.0.0";
        memorize = false;
        _shouldPropagate = true;
        active = true;
    }

    public function dispatch(args:Array<Dynamic>):Void {
        if (active) {
            _prevParams = args;
            var bindings:Array<SignalBinding> = _bindings.copy();
            for (binding in bindings) {
                if (_shouldPropagate) {
                    binding.execute(args);
                }
            }
        }
    }

    public function _registerListener(listener:Dynamic, isOnce:Bool, context:Dynamic, priority:Int = 0):SignalBinding {
        var index:Int = _indexOfListener(listener, context);
        if (index != -1) {
            var binding:SignalBinding = _bindings[index];
            if (binding.isOnce() != isOnce) {
                throw "You cannot add" + (isOnce ? "" : "Once") + "() then add" + (!isOnce ? "" : "Once") + "() the same listener without removing the relationship first.";
            }
        } else {
            binding = new SignalBinding(this, listener, isOnce, context, priority);
            _addBinding(binding);
        }
        if (memorize && _prevParams != null) {
            binding.execute(_prevParams);
        }
        return binding;
    }

    public function _addBinding(binding:SignalBinding):Void {
        var index:Int = _bindings.length;
        while (index > 0 && _bindings[index - 1]._priority >= binding._priority) {
            index--;
        }
        _bindings.insert(index, binding);
    }

    public function _indexOfListener(listener:Dynamic, context:Dynamic):Int {
        for (i in 0..._bindings.length) {
            if (_bindings[i]._listener == listener && _bindings[i].context == context) {
                return i;
            }
        }
        return -1;
    }

    public function has(listener:Dynamic, context:Dynamic):Bool {
        return _indexOfListener(listener, context) != -1;
    }

    public function add(listener:Dynamic, context:Dynamic, priority:Int = 0):SignalBinding {
        return _registerListener(listener, false, context, priority);
    }

    public function addOnce(listener:Dynamic, context:Dynamic, priority:Int = 0):SignalBinding {
        return _registerListener(listener, true, context, priority);
    }

    public function remove(listener:Dynamic, context:Dynamic):Dynamic {
        var index:Int = _indexOfListener(listener, context);
        if (index != -1) {
            _bindings[index]._destroy();
            _bindings.splice(index, 1);
        }
        return listener;
    }

    public function removeAll():Void {
        for (i in 0..._bindings.length) {
            _bindings[i]._destroy();
        }
        _bindings.length = 0;
    }

    public function getNumListeners():Int {
        return _bindings.length;
    }

    public function halt():Void {
        _shouldPropagate = false;
    }

    public function forget():Void {
        _prevParams = null;
    }

    public function dispose():Void {
        removeAll();
        _bindings = null;
        _prevParams = null;
    }

    public function toString():String {
        return "[Signal active:" + active + " numListeners:" + getNumListeners() + "]";
    }
}

class Signals {
    public static var Signal:Signal;
}

// Exporting the Signal class
if (typeof(define) == "function" && define.amd) {
    define(function() {
        return Signals.Signal;
    });
} else if (typeof(module) != "undefined" && module.exports) {
    module.exports = Signals.Signal;
} else {
    js.Lib.signals = Signals.Signal;
}
```
Note that I've kept the original JavaScript code's comments and formatting style to make it easier to compare with the original code. Also, I've used the Haxe `js` library to make the code compatible with JavaScript.