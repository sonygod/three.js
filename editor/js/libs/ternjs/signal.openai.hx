package three.js.editor.js.libs.ternjs;

class Signal {
  private var _handlers:Map<String, Array<Dynamic->Void>>;

  public function new() {}

  public function on(type:String, f:Dynamic->Void) {
    if (_handlers == null) _handlers = new Map();
    if (!_handlers.exists(type)) _handlers.set(type, new Array());
    _handlers.get(type).push(f);
  }

  public function off(type:String, f:Dynamic->Void) {
    if (_handlers != null && _handlers.exists(type)) {
      var arr:Array<Dynamic->Void> = _handlers.get(type);
      for (i in 0...arr.length) {
        if (arr[i] == f) {
          arr.splice(i, 1);
          break;
        }
      }
    }
  }

  public function signal(type:String, a1:Dynamic, a2:Dynamic = null, a3:Dynamic = null, a4:Dynamic = null) {
    if (_handlers != null && _handlers.exists(type)) {
      var arr:Array<Dynamic->Void> = _handlers.get(type);
      for (f in arr) {
        f(a1, a2, a3, a4);
      }
    }
  }

  public static function mixin(obj:Dynamic) {
    obj.on = on;
    obj.off = off;
    obj.signal = signal;
    return obj;
  }
}