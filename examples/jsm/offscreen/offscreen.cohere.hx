import js.Browser.Self;
import js.Browser.Worker;

class Main {
    static function main() {
        Self.onmessage = function(message:MessageEvent) {
            var data = message.data;
            init(data.drawingSurface, data.width, data.height, data.pixelRatio, data.path);
        };
    }
}