import js.html.WorkerGlobalScope;

class OffscreenCanvasWorkerCubes {
    static var state:Dynamic = { width:0, height:0 };

    static function init():Void {
        // Initialize state here
    }

    static function size(data:Dynamic):Void {
        state.width = data.width;
        state.height = data.height;
    }

    static var handlers:Map<String, Void->Void> = [
        'init' => init,
        'size' => size
    ];

    static function main():Void {
        js.Browser.window.onmessage = function(e:Dynamic) {
            var fn = handlers.get(e.data.type);
            if (fn == null) {
                throw new Error('no handler for type: ' + e.data.type);
            }
            fn(e.data);
        };
    }
}