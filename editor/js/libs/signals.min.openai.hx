// Signals.hx
package signals;

class SignalBinding<T>
{
    public var _listener:T->Void;
    public var _isOnce:Bool;
    public var context:Dynamic;
    public var _signal:Signal<T>;
    public var _priority:Int;

    public function new(signal:Signal<T>, listener:T->Void, isOnce:Bool, context:Dynamic, priority:Int = 0)
    {
        _listener = listener;
        _isOnce = isOnce;
        this.context = context;
        _signal = signal;
        _priority = priority;
    }

    public var active(get, set):Bool;
    public var params:Array<Dynamic>;

    public function execute(args:Array<Dynamic>):Dynamic
    {
        if (active)
        {
            var params:Array<Dynamic> = this.params != null ? this.params.concat(args) : args;
            var result:Dynamic = _listener.apply(context, params);
            if (_isOnce)
                detach();
            return result;
        }
        return null;
    }

    public function detach():Void
    {
        if (isBound())
            _signal.remove(_listener, context);
    }

    public function isBound():Bool
    {
        return _signal != null && _listener != null;
    }

    public function isOnce():Bool
    {
        return _isOnce;
    }

    public function getListener():T->Void
    {
        return _listener;
    }

    public function getSignal():Signal<T>
    {
        return _signal;
    }

    public function toString():String
    {
        return "[SignalBinding isOnce:" + _isOnce + ", isBound:" + isBound() + ", active:" + active + "]";
    }
}

class Signal<T>
{
    public var _bindings:Array<SignalBinding<T>> = [];
    public var _prevParams:Array<Dynamic>;
    public var memeorize:Bool = false;
    public var _shouldPropagate:Bool = true;
    public var active:Bool = true;

    public function new()
    {
        //
    }

    public function _registerListener(listener:T->Void, isOnce:Bool, context:Dynamic, priority:Int = 0):SignalBinding<T>
    {
        var index:Int = _indexOfListener(listener, context);
        if (index != -1)
        {
            if (listener != _bindings[index]._listener || context != _bindings[index].context)
                throw "Cannot add" + (isOnce ? "Once" : "") + " then add" + (!isOnce ? "Once" : "") + " the same listener without removing the relationship first.";
        }
        else
        {
            var binding:SignalBinding<T> = new SignalBinding<T>(this, listener, isOnce, context, priority);
            _addBinding(binding);
            if (memeorize && _prevParams != null)
                binding.execute(_prevParams);
            return binding;
        }
        return _bindings[index];
    }

    public function _addBinding(binding:SignalBinding<T>):Void
    {
        var index:Int = _bindings.length;
        while (index > 0 && _bindings[index - 1]._priority <= binding._priority)
        {
            index--;
        }
        _bindings.insert(index, binding);
    }

    public function _indexOfListener(listener:T->Void, context:Dynamic):Int
    {
        for (i in 0..._bindings.length)
        {
            if (_bindings[i]._listener == listener && _bindings[i].context == context)
                return i;
        }
        return -1;
    }

    public function has(listener:T->Void, context:Dynamic):Bool
    {
        return _indexOfListener(listener, context) != -1;
    }

    public function add(listener:T->Void, context:Dynamic = null):SignalBinding<T>
    {
        return _registerListener(listener, false, context);
    }

    public function addOnce(listener:T->Void, context:Dynamic = null):SignalBinding<T>
    {
        return _registerListener(listener, true, context);
    }

    public function remove(listener:T->Void, context:Dynamic):Void
    {
        var index:Int = _indexOfListener(listener, context);
        if (index != -1)
        {
            _bindings[index]._destroy();
            _bindings.splice(index, 1);
        }
    }

    public function removeAll():Void
    {
        for (i in _bindings.length...0)
        {
            _bindings[i]._destroy();
        }
        _bindings = [];
    }

    public function getNumListeners():Int
    {
        return _bindings.length;
    }

    public function halt():Void
    {
        _shouldPropagate = false;
    }

    public function dispatch(args:Array<Dynamic>):Void
    {
        if (active)
        {
            var params:Array<Dynamic> = args.slice();
            if (memeorize)
                _prevParams = params;
            var bindings:Array<SignalBinding<T>> = _bindings.slice();
            for (binding in bindings)
            {
                if (_shouldPropagate && binding.execute(params) === false)
                    _shouldPropagate = false;
            }
        }
    }

    public function forget():Void
    {
        _prevParams = null;
    }

    public function dispose():Void
    {
        removeAll();
        _bindings = null;
        _prevParams = null;
    }

    public function toString():String
    {
        return "[Signal active:" + active + " numListeners:" + getNumListeners() + "]";
    }
}