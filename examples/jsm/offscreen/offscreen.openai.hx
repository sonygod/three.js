import js.htmlWorker.Worker;
import js.htmlWorker.WorkerScope;

class Offscreen {
  static function main() {
    WorkerScope.self.onmessage = function(message) {
      var data:Dynamic = message.data;
      init(data.drawingSurface, data.width, data.height, data.pixelRatio, data.path);
    }
  }
}