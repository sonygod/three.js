class Signal {
    private var _bindings:Array<SignalBinding>;
    private var _prevParams:Array<Dynamic>;
    private var _shouldPropagate:Bool = true;
    public var active:Bool = true;

    public function new() {
        _bindings = [];
        _prevParams = null;
    }

    private function _indexOfListener(listener:Dynamic, context:Dynamic):Int {
        for (i in _bindings.length) {
            var binding = _bindings[i];
            if (binding._listener == listener && binding.context == context) {
                return i;
            }
        }
        return -1;
    }

    private function _addBinding(binding:SignalBinding) {
        var index = _bindings.length;
        do {
            index--;
        } while (index >= 0 && binding._priority <= _bindings[index]._priority);
        _bindings.splice(index + 1, 0, binding);
    }

    private function _registerListener(listener:Dynamic, isOnce:Bool, context:Dynamic, priority:Int):SignalBinding {
        var index = _indexOfListener(listener, context);
        if (index != -1) {
            var binding = _bindings[index];
            if (binding.isOnce() != isOnce) {
                throw "You cannot add" + (isOnce ? "" : "Once") + "() then add" + (isOnce ? "Once" : "") + "() the same listener without removing the relationship first.";
            }
        } else {
            var binding = new SignalBinding(this, listener, isOnce, context, priority);
            _addBinding(binding);
            if (this.memorize && _prevParams != null) {
                binding.execute(_prevParams);
            }
        }
        return binding;
    }

    public function add(listener:Dynamic, context:Dynamic = null, priority:Int = 0):SignalBinding {
        return _registerListener(listener, false, context, priority);
    }

    public function addOnce(listener:Dynamic, context:Dynamic = null, priority:Int = 0):SignalBinding {
        return _registerListener(listener, true, context, priority);
    }

    public function remove(listener:Dynamic, context:Dynamic = null):Dynamic {
        var index = _indexOfListener(listener, context);
        if (index != -1) {
            _bindings[index]._destroy();
            _bindings.splice(index, 1);
        }
        return listener;
    }

    public function removeAll():Void {
        for (i in _bindings.length) {
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

    public function dispatch(params:Array<Dynamic>):Void {
        if (active) {
            var args = params.slice();
            var count = _bindings.length;
            if (memorize) {
                _prevParams = args;
            }
            if (count > 0) {
                var bindings = _bindings.slice();
                _shouldPropagate = true;
                while (count > 0 && _shouldPropagate) {
                    count--;
                    if (bindings[count] != null) {
                        bindings[count].execute(args);
                    }
                }
            }
        }
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

class SignalBinding {
    private var _listener:Dynamic;
    private var _isOnce:Bool;
    public var context:Dynamic;
    private var _signal:Signal;
    private var _priority:Int;

    public function new(signal:Signal, listener:Dynamic, isOnce:Bool, context:Dynamic, priority:Int) {
        _listener = listener;
        _isOnce = isOnce;
        this.context = context;
        _signal = signal;
        _priority = priority;
    }

    public function execute(params:Array<Dynamic>):Dynamic {
        if (active && _listener != null) {
            params = this.params ? this.params.concat(params) : params;
            var result = _listener.apply(context, params);
            if (_isOnce) {
                detach();
            }
            return result;
        }
        return null;
    }

    public function detach():Dynamic {
        return isBound() ? _signal.remove(_listener, context) : null;
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

    private function _destroy():Void {
        _signal = null;
        _listener = null;
        context = null;
    }

    public function toString():String {
        return "[SignalBinding isOnce:" + _isOnce + ", isBound:" + isBound() + ", active:" + active + "]";
    }
}