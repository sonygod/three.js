class Signal {
    private var _handlers:Map<String, Array<Dynamic->Void>>;

    public function new() {
        _handlers = new Map();
    }

    public function on(type:String, f:Dynamic->Void) {
        var handlers = _handlers.exists(type) ? _handlers.get(type) : [];
        handlers.push(f);
        _handlers.set(type, handlers);
    }

    public function off(type:String, f:Dynamic->Void) {
        if (_handlers.exists(type)) {
            var arr = _handlers.get(type);
            for (i in 0...arr.length) {
                if (arr[i] == f) {
                    arr.splice(i, 1);
                    break;
                }
            }
        }
    }

    public function signal(type:String, a1:Dynamic, a2:Dynamic, a3:Dynamic, a4:Dynamic) {
        if (_handlers.exists(type)) {
            var arr = _handlers.get(type);
            for (i in 0...arr.length) {
                arr[i].apply(this, [a1, a2, a3, a4]);
            }
        }
    }

    static public function mixin(obj:Dynamic) {
        obj.on = on;
        obj.off = off;
        obj.signal = signal;
        return obj;
    }
}