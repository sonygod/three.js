extern class Scene {
    public static function init(drawingSurface:Dynamic, width:Int, height:Int, pixelRatio:Float, path:String):Void;
}


Then, you can use it in your main class:


class Offscreen {
    public function new() {
        js.Browser.window.onmessage = (message:Dynamic) -> {
            var data = message.data;
            Scene.init(data.drawingSurface, data.width.toInt(), data.height.toInt(), data.pixelRatio.toFloat(), data.path);
        };
    }
}