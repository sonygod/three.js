package tern.signal;

class Signal {
  private var _handlers: haxe.ds.StringMap<Array<Dynamic>>;

  public function on(type: String, f: Dynamic): Void {
    if (this._handlers == null) this._handlers = new haxe.ds.StringMap<Array<Dynamic>>();
    var handlers = this._handlers;
    if (!handlers.exists(type)) handlers.set(type, []);
    handlers.get(type).push(f);
  }

  public function off(type: String, f: Dynamic): Void {
    if (this._handlers != null) {
      var arr = this._handlers.get(type);
      if (arr != null) {
        var i = arr.indexOf(f);
        if (i != -1) arr.splice(i, 1);
      }
    }
  }

  public function signal(type: String, a1: Dynamic = null, a2: Dynamic = null, a3: Dynamic = null, a4: Dynamic = null): Void {
    if (this._handlers != null) {
      var arr = this._handlers.get(type);
      if (arr != null) {
        for (var i = 0; i < arr.length; ++i) arr[i](a1, a2, a3, a4);
      }
    }
  }

  public static function mixin(obj: Dynamic): Dynamic {
    obj.on = function(type: String, f: Dynamic): Void {
      this.signal.on(type, f);
    };
    obj.off = function(type: String, f: Dynamic): Void {
      this.signal.off(type, f);
    };
    obj.signal = function(type: String, a1: Dynamic = null, a2: Dynamic = null, a3: Dynamic = null, a4: Dynamic = null): Void {
      this.signal.signal(type, a1, a2, a3, a4);
    };
    return obj;
  }
}