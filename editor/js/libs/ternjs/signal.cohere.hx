class Signal {
    private var _handlers:Map<String, Array<Function>> = Map();

    public function on(type:String, f:Function):Void {
        var arr = _handlers.get(type);
        if (arr == null) {
            arr = [];
            _handlers.set(type, arr);
        }
        arr.push(f);
    }

    public function off(type:String, f:Function):Void {
        var arr = _handlers.get(type);
        if (arr != null) {
            for (i in 0...arr.length) {
                if (arr[i] == f) {
                    arr.splice(i, 1);
                    break;
                }
            }
        }
    }

    public function signal(type:String, a1:Dynamic, a2:Dynamic, a3:Dynamic, a4:Dynamic):Void {
        var arr = _handlers.get(type);
        if (arr != null) {
            for (f in arr) {
                f(a1, a2, a3, a4);
            }
        }
    }

    public static function mixin(obj:Dynamic):Dynamic {
        obj.on = function(type:String, f:Function):Void {
            var arr = obj._handlers.get(type);
            if (arr == null) {
                arr = [];
                obj._handlers.set(type, arr);
            }
            arr.push(f);
        };
        obj.off = function(type:String, f:Function):Void {
            var arr = obj._handlers.get(type);
            if (arr != null) {
                for (i in 0...arr.length) {
                    if (arr[i] == f) {
                        arr.splice(i, 1);
                        break;
                    }
                }
            }
        };
        obj.signal = function(type:String, a1:Dynamic, a2:Dynamic, a3:Dynamic, a4:Dynamic):Void {
            var arr = obj._handlers.get(type);
            if (arr != null) {
                for (f in arr) {
                    f(a1, a2, a3, a4);
                }
            }
        };
        return obj;
    }
}