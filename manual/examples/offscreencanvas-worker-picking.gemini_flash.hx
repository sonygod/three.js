import sharedPicking.state;
import sharedPicking.pickPosition;
import sharedPicking.init;

class Main {

  static function size(data:Dynamic) {
    state.width = data.width;
    state.height = data.height;
  }

  static function mouse(data:Dynamic) {
    pickPosition.x = data.x;
    pickPosition.y = data.y;
  }

  static function main() {
    var handlers:Map<String,Dynamic> = new Map();
    handlers.set("init", init);
    handlers.set("mouse", mouse);
    handlers.set("size", size);

    js.Browser.window.onmessage = function(e:Dynamic) {
      var fn = handlers.get(e.data.type);
      if (fn == null) {
        throw new Error("no handler for type: " + e.data.type);
      }
      fn(e.data);
    };
  }
}

class sharedPicking {
  static class state {
    public static var width:Int;
    public static var height:Int;
  }

  static class pickPosition {
    public static var x:Int;
    public static var y:Int;
  }

  static function init() {
    // Implement your initialization logic here
    // This is a placeholder for example purposes
    trace("Initialization complete");
  }
}