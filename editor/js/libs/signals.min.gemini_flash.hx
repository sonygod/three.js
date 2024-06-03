package;

import js.html.Array;

class SignalBinding {
  public var _listener:Dynamic;
  public var _isOnce:Bool;
  public var context:Dynamic;
  public var _signal:Signal;
  public var _priority:Int;

  public var active:Bool = true;
  public var params:Array<Dynamic> = null;

  public function new(signal:Signal, listener:Dynamic, isOnce:Bool, context:Dynamic, priority:Int = 0) {
    this._listener = listener;
    this._isOnce = isOnce;
    this.context = context;
    this._signal = signal;
    this._priority = priority;
  }

  public function execute(params:Array<Dynamic>):Dynamic {
    if (this.active && this._listener != null) {
      var combinedParams = (this.params != null) ? this.params.concat(params) : params;
      var result = this._listener.apply(this.context, combinedParams);
      if (this._isOnce) this.detach();
      return result;
    }
    return null;
  }

  public function detach():SignalBinding {
    if (this.isBound()) {
      return this._signal.remove(this._listener, this.context);
    }
    return null;
  }

  public function isBound():Bool {
    return this._signal != null && this._listener != null;
  }

  public function isOnce():Bool {
    return this._isOnce;
  }

  public function getListener():Dynamic {
    return this._listener;
  }

  public function getSignal():Signal {
    return this._signal;
  }

  public function _destroy() {
    delete this._signal;
    delete this._listener;
    delete this.context;
  }

  public function toString():String {
    return "[SignalBinding isOnce:" + this._isOnce + ", isBound:" + this.isBound() + ", active:" + this.active + "]";
  }
}

class Signal {
  public static var VERSION:String = "1.0.0";
  public var memorize:Bool = false;
  public var _shouldPropagate:Bool = true;
  public var active:Bool = true;
  public var _bindings:Array<SignalBinding> = [];
  public var _prevParams:Array<Dynamic> = null;

  public function new() {
    var a = this;
    this.dispatch = function(args:Array<Dynamic>):Void {
      Signal.prototype.dispatch.apply(a, args);
    };
  }

  public function _registerListener(listener:Dynamic, isOnce:Bool, context:Dynamic, priority:Int):SignalBinding {
    var index = this._indexOfListener(listener, context);
    if (index != -1) {
      var binding = this._bindings[index];
      if (binding.isOnce() != isOnce) {
        throw "You cannot add" + (isOnce ? "" : "Once") + "() then add" + (!isOnce ? "" : "Once") + "() the same listener without removing the relationship first.";
      }
    } else {
      var binding = new SignalBinding(this, listener, isOnce, context, priority);
      this._addBinding(binding);
    }
    if (this.memorize && this._prevParams != null) {
      binding.execute(this._prevParams);
    }
    return binding;
  }

  public function _addBinding(binding:SignalBinding) {
    var i = this._bindings.length;
    while (i-- && this._bindings[i] != null && binding._priority <= this._bindings[i]._priority) {
    }
    this._bindings.splice(i + 1, 0, binding);
  }

  public function _indexOfListener(listener:Dynamic, context:Dynamic):Int {
    for (var i = this._bindings.length; i--;) {
      var binding = this._bindings[i];
      if (binding._listener == listener && binding.context == context) {
        return i;
      }
    }
    return -1;
  }

  public function has(listener:Dynamic, context:Dynamic):Bool {
    return this._indexOfListener(listener, context) != -1;
  }

  public function add(listener:Dynamic, context:Dynamic = null, priority:Int = 0):SignalBinding {
    if (typeof listener != "function") throw "listener is a required param of {fn}() and should be a Function.".replace("{fn}", "add");
    return this._registerListener(listener, false, context, priority);
  }

  public function addOnce(listener:Dynamic, context:Dynamic = null, priority:Int = 0):SignalBinding {
    if (typeof listener != "function") throw "listener is a required param of {fn}() and should be a Function.".replace("{fn}", "addOnce");
    return this._registerListener(listener, true, context, priority);
  }

  public function remove(listener:Dynamic, context:Dynamic = null):Dynamic {
    if (typeof listener != "function") throw "listener is a required param of {fn}() and should be a Function.".replace("{fn}", "remove");
    var index = this._indexOfListener(listener, context);
    if (index != -1) {
      this._bindings[index]._destroy();
      this._bindings.splice(index, 1);
      return listener;
    }
    return null;
  }

  public function removeAll() {
    for (var i = this._bindings.length; i--;) {
      this._bindings[i]._destroy();
    }
    this._bindings.length = 0;
  }

  public function getNumListeners():Int {
    return this._bindings.length;
  }

  public function halt() {
    this._shouldPropagate = false;
  }

  public function dispatch(args:Array<Dynamic>):Void {
    if (this.active) {
      var params = Array.prototype.slice.call(args);
      var i = this._bindings.length;
      var binding:SignalBinding;
      if (this.memorize) {
        this._prevParams = params;
      }
      if (i) {
        var bindings = this._bindings.slice();
        this._shouldPropagate = true;
        while (i-- && bindings[i] != null && this._shouldPropagate) {
          binding = bindings[i];
          binding.execute(params);
        }
      }
    }
  }

  public function forget() {
    this._prevParams = null;
  }

  public function dispose() {
    this.removeAll();
    delete this._bindings;
    delete this._prevParams;
  }

  public function toString():String {
    return "[Signal active:" + this.active + " numListeners:" + this.getNumListeners() + "]";
  }
}

class Signals {
  public static var Signal:Signal = Signal;
}