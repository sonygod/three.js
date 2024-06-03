import three.js.manual.examples.SharedCubes;

class OffscreenCanvasWorkerCubes {
    public static function main() {
        var handlers:Map<String, Function> = new Map<String, Function>();
        handlers.set("init", SharedCubes.init);
        handlers.set("size", size);

        js.Browser.window.onmessage = function(e:Dynamic) {
            var fn = handlers.get(e.data.type);
            if (Std.is(fn, Function)) {
                fn(e.data);
            } else {
                throw js.Error("no handler for type: " + e.data.type);
            }
        };
    }

    public static function size(data:Dynamic) {
        SharedCubes.state.width = data.width;
        SharedCubes.state.height = data.height;
    }
}