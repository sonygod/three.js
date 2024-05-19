import js.html.WorkerGlobalScope;

class OffscreenCanvasWorkerPicking {
    static var state:Dynamic = {};
    static var pickPosition:Dynamic = {};

    static function init(data:Dynamic):Void {
        // no-op, assuming init is defined in shared-picking.js
    }

    static function size(data:Dynamic):Void {
        state.width = data.width;
        state.height = data.height;
    }

    static function mouse(data:Dynamic):Void {
        pickPosition.x = data.x;
        pickPosition.y = data.y;
    }

    static var handlers:Dynamic = {
        init: init,
        mouse: mouse,
        size: size
    };

    static function main():Void {
        js.Browser.window.self.onmessage = function(e:Dynamic):Void {
            var fn:Dynamic = handlers[e.data.type];
            if (js.Lib.isInstanceOf(fn, js.Lib.Function)) {
                fn(e.data);
            } else {
                throw new js.Error('no handler for type: ' + e.data.type);
            }
        };
    }

    static function new() {
        main();
    }
}