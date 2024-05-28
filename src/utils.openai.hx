package three.js.src;

class Utils {
    public static function arrayMin(array:Array<Float>):Float {
        if (array.length == 0) return Math.POSITIVE_INFINITY;
        var min = array[0];
        for (i in 1...array.length) {
            if (array[i] < min) min = array[i];
        }
        return min;
    }

    public static function arrayMax(array:Array<Float>):Float {
        if (array.length == 0) return Math.NEGATIVE_INFINITY;
        var max = array[0];
        for (i in 1...array.length) {
            if (array[i] > max) max = array[i];
        }
        return max;
    }

    public static function arrayNeedsUint32(array:Array<Int>):Bool {
        for (i in array.length - 1...0) {
            if (array[i] >= 65535) return true;
        }
        return false;
    }

    public static var TYPED_ARRAYS = [
        "Int8Array" => js.html.Int8Array,
        "Uint8Array" => js.html.Uint8Array,
        "Uint8ClampedArray" => js.html.Uint8ClampedArray,
        "Int16Array" => js.html.Int16Array,
        "Uint16Array" => js.html.Uint16Array,
        "Int32Array" => js.html.Int32Array,
        "Uint32Array" => js.html.Uint32Array,
        "Float32Array" => js.html.Float32Array,
        "Float64Array" => js.html.Float64Array
    ];

    public static function getTypedArray(type:String, buffer:js.lib.ArrayBuffer):Dynamic {
        return new TYPED_ARRAYS[type](buffer);
    }

    public static function createElementNS(name:String):js.html.Element {
        return js.Browser.document.createElementNS("http://www.w3.org/1999/xhtml", name);
    }

    public static function createCanvasElement():js.html.CanvasElement {
        var canvas = createElementNS("canvas");
        canvas.style.display = "block";
        return canvas;
    }

    private static var _cache:Map<String, Bool> = new Map();

    public static function warnOnce(message:String):Void {
        if (_cache.exists(message)) return;
        _cache.set(message, true);
        js.Browser.console.warn(message);
    }

    public static function probeAsync(gl:js.web.gl.RenderingContext, sync:js.web.gl.Sync, interval:Int):js.Promise<Void> {
        return new js.Promise(function(resolve, reject) {
            function probe():Void {
                switch (gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0)) {
                    case gl.WAIT_FAILED:
                        reject();
                    case gl.TIMEOUT_EXPIRED:
                        haxe.Timer.delay(probe, interval);
                    default:
                        resolve();
                }
            }
            haxe.Timer.delay(probe, interval);
        });
    }
}