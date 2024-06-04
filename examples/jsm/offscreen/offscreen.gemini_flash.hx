import js.Browser;

class Worker {
  public static function main():Void {
    Browser.window.onmessage = function(message:Dynamic) {
      var data = message.data;
      Scene.init(data.drawingSurface, data.width, data.height, data.pixelRatio, data.path);
    };
  }
}