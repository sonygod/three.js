class Signal {

  public var _handlers:Map<String,Array<Dynamic>>;

  public function new() {
    _handlers = new Map();
  }

  public function on(type:String, f:Dynamic):Void {
    var handlers = _handlers.get(type);
    if (handlers == null) {
      handlers = [];
      _handlers.set(type, handlers);
    }
    handlers.push(f);
  }

  public function off(type:String, f:Dynamic):Void {
    var arr = _handlers.get(type);
    if (arr != null) {
      for (i in 0...arr.length) {
        if (arr[i] == f) {
          arr.splice(i, 1);
          break;
        }
      }
    }
  }

  public function signal(type:String, a1:Dynamic = null, a2:Dynamic = null, a3:Dynamic = null, a4:Dynamic = null):Void {
    var arr = _handlers.get(type);
    if (arr != null) {
      for (i in 0...arr.length) {
        arr[i].call(this, a1, a2, a3, a4);
      }
    }
  }

  public static function mixin(obj:Dynamic):Dynamic {
    obj.on = on;
    obj.off = off;
    obj.signal = signal;
    return obj;
  }
}