package three.js.editor.js.libs.ternjs;

class Signal {
  private var _handlers:Dynamic = {};

  public function on(type:String, f:Dynamic):Void {
    var handlers = _handlers[type] || (_handlers[type] = []);
    handlers.push(f);
  }

  public function off(type:String, f:Dynamic):Void {
    var arr:Array<Dynamic> = _handlers[type];
    if (arr != null) {
      for (i in 0...arr.length) {
        if (arr[i] == f) {
          arr.splice(i, 1);
          break;
        }
      }
    }
  }

  public function signal(type:String, a1:Dynamic, a2:Dynamic, a3:Dynamic, a4:Dynamic):Void {
    var arr:Array<Dynamic> = _handlers[type];
    if (arr != null) {
      for (i in 0...arr.length) {
        arr[i](a1, a2, a3, a4);
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