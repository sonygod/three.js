package three.js.examples.jsm.offscreen;

import js.html.WorkerGlobalScope;
import js.lib.Error;

class Offscreen {
  public function new() {}

  public function main() {
    WorkerGlobalScope.self.onmessage = function(message:Dynamic) {
      var data:Dynamic = message.data;
      init(data.drawingSurface, data.width, data.height, data.pixelRatio, data.path);
    };
  }
}