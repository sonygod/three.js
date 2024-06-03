import js.html.Worker;
import js.html.MessageEvent;

class OffscreenCanvasWorkerCubes {
  static var state:Dynamic = {};
  static var handlers:Dynamic = {};

  static function init(data:Dynamic) {
    // TO DO: implement init function from shared-cubes.js
  }

  static function size(data:Dynamic) {
    state.width = data.width;
    state.height = data.height;
  }

  static function main() {
    handlers = {
      init: init,
      size: size
    };

    Worker.global.onmessage = function(event:MessageEvent) {
      var fn = handlers[event.data.type];
      if (Reflect.isFunction(fn)) {
        fn(event.data);
      } else {
        throw new Error('no handler for type: ' + event.data.type);
      }
    };
  }
}