import haxe.concurrent.Thread;
import haxe.io.Bytes;

class PickingWorker {
  static var state = {};
  static var pickPosition = { x: 0, y: 0 };

  static function size(data:Dynamic) {
    state.width = data.width;
    state.height = data.height;
  }

  static function mouse(data:Dynamic) {
    pickPosition.x = data.x;
    pickPosition.y = data.y;
  }

  static var handlers = [
    "init" => init,
    "mouse" => mouse,
    "size" => size
  ];

  static function main() {
    Thread.create(() -> {
      while (true) {
        var message:Dynamic = Thread.readMessage(true);
        var fn = handlers.get(message.type);
        if (fn == null) {
          throw new Error('no handler for type: ' + message.type);
        }
        fn(message.data);
      }
    });
  }
}

Note that in Haxe, we don't have a direct equivalent to `self.onmessage` since Haxe targets multiple platforms and environments. Instead, we use the `Thread` API to create a worker thread that listens for messages.

Also, I assumed that the `init` function is defined elsewhere in your codebase, so I didn't include its implementation here.

You can compile this code using the Haxe compiler with the `-cp` flag set to the directory containing your `shared-picking.js` file, like this:

haxe -cp . -main PickingWorker -js output.js