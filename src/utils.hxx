class Utils {
    public static function arrayMin(array:Array<Float>):Float {
        if (array.length == 0) return Infinity;
        var min = array[0];
        for (i in 1...array.length) {
            if (array[i] < min) min = array[i];
        }
        return min;
    }

    public static function arrayMax(array:Array<Float>):Float {
        if (array.length == 0) return -Infinity;
        var max = array[0];
        for (i in 1...array.length) {
            if (array[i] > max) max = array[i];
        }
        return max;
    }

    public static function arrayNeedsUint32(array:Array<Int>):Bool {
        for (i in Std.int(array.length - 1)...0 by -1) {
            if (array[i] >= 65535) return true;
        }
        return false;
    }

    public static function getTypedArray(type:String, buffer:haxe.io.Bytes):haxe.io.Bytes {
        var typedArray:haxe.io.Bytes;
        switch (type) {
            case "Int8Array":
                typedArray = new Int8Array(buffer);
                break;
            case "Uint8Array":
                typedArray = new Uint8Array(buffer);
                break;
            case "Uint8ClampedArray":
                typedArray = new Uint8ClampedArray(buffer);
                break;
            case "Int16Array":
                typedArray = new Int16Array(buffer);
                break;
            case "Uint16Array":
                typedArray = new Uint16Array(buffer);
                break;
            case "Int32Array":
                typedArray = new Int32Array(buffer);
                break;
            case "Uint32Array":
                typedArray = new Uint32Array(buffer);
                break;
            case "Float32Array":
                typedArray = new Float32Array(buffer);
                break;
            case "Float64Array":
                typedArray = new Float64Array(buffer);
                break;
        }
        return typedArray;
    }

    public static function createElementNS(name:String):haxe.xml.Node {
        return new haxe.xml.Node(name);
    }

    public static function createCanvasElement():haxe.xml.Node {
        var canvas = createElementNS("canvas");
        canvas.style.display = "block";
        return canvas;
    }

    private static var _cache:Map<String, Bool> = new Map();

    public static function warnOnce(message:String):Void {
        if (_cache.exists(message)) return;
        _cache[message] = true;
        trace(message, 'warn');
    }

    public static function probeAsync(gl:haxe.web.WebGLRenderingContext, sync:haxe.web.WebGLSync, interval:Int):Promise<Void> {
        return new Promise(function(resolve, reject) {
            function probe() {
                switch (gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0)) {
                    case gl.WAIT_FAILED:
                        reject();
                        break;
                    case gl.TIMEOUT_EXPIRED:
                        haxe.Timer.delay(function() { probe(); }, interval);
                        break;
                    default:
                        resolve();
                }
            }
            haxe.Timer.delay(function() { probe(); }, interval);
        });
    }
}