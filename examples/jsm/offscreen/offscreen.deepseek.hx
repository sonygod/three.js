import js.html.Worker;
import js.html.MessageEvent;

class OffscreenWorker {

    static function main() {
        var worker = new Worker('./scene.js');

        worker.onmessage = function(event:MessageEvent) {
            var data = event.data;
            init(data.drawingSurface, data.width, data.height, data.pixelRatio, data.path);
        };
    }

    static function init(drawingSurface:Dynamic, width:Int, height:Int, pixelRatio:Float, path:String) {
        // 这里是你的代码
    }
}