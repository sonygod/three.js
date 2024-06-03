import js.html.WebWorkerGlobalScope;
import SharedPicking;

class OffscreenCanvasWorkerPicking {

    private static var state: SharedPicking.State = SharedPicking.state;
    private static var pickPosition: SharedPicking.Vector2 = SharedPicking.pickPosition;

    public static function size(data: Dynamic): Void {
        state.width = data.width;
        state.height = data.height;
    }

    public static function mouse(data: Dynamic): Void {
        pickPosition.x = data.x;
        pickPosition.y = data.y;
    }

    public static function main(): Void {
        var handlers: Map<String, Function<Dynamic, Void>> = new Map<String, Function<Dynamic, Void>>();
        handlers.set("init", SharedPicking.init);
        handlers.set("mouse", mouse);
        handlers.set("size", size);

        WebWorkerGlobalScope.self.onmessage = function(e: MessageEvent) {
            var fn = handlers.get(e.data.type);
            if (fn == null) {
                throw new js._Error("no handler for type: " + e.data.type);
            }

            fn(e.data);
        };
    }
}