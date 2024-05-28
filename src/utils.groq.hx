package three.utils;

class Utils {
    public static function arrayMin(array:Array<Float>):Float {
        if (array.length == 0) return Math.POSITIVE_INFINITY;
        var min:Float = array[0];
        for (i in 1...array.length) {
            if (array[i] < min) min = array[i];
        }
        return min;
    }

    public static function arrayMax(array:Array<Float>):Float {
        if (array.length == 0) return Math.NEGATIVE_INFINITY;
        var max:Float = array[0];
        for (i in 1...array.length) {
            if (array[i] > max) max = array[i];
        }
        return max;
    }

    public static function arrayNeedsUint32(array:Array<Int>):Bool {
        // assumes larger values usually on last
        for (i in array.length - 1...0) {
            if (array[i] >= 65535) return true; // account for PRIMITIVE_RESTART_FIXED_INDEX, #24565
        }
        return false;
    }

    private static var TYPED_ARRAYS = [
        "Int8Array" => JS('Int8Array'),
        "Uint8Array" => JS('Uint8Array'),
        "Uint8ClampedArray" => JS('Uint8ClampedArray'),
        "Int16Array" => JS('Int16Array'),
        "Uint16Array" => JS('Uint16Array'),
        "Int32Array" => JS('Int32Array'),
        "Uint32Array" => JS('Uint32Array'),
        "Float32Array" => JS('Float32Array'),
        "Float64Array" => JS('Float64Array')
    ];

    public static function getTypedArray(type:String, buffer:Dynamic):Dynamic {
        return new TYPED_ARRAYS[type](buffer);
    }

    public static function createElementNS(name:String):js.html.Element {
        return js.Browser.document.createElementNS('http://www.w3.org/1999/xhtml', name);
    }

    public static function createCanvasElement():js.html.CanvasElement {
        var canvas:js.html.CanvasElement = createElementNS('canvas');
        canvas.style.display = 'block';
        return canvas;
    }

    private static var _cache:Map<String, Bool> = new Map();

    public static function warnOnce(message:String):Void {
        if (_cache.exists(message)) return;
        _cache[message] = true;
        js.Lib.console.warn(message);
    }

    public static function probeAsync(gl:js.webgl.RenderingContext, sync:js.webgl.Sync, interval:Int):js.Promise<Void> {
        return new js.Promise(function(resolve, reject) {
            function probe():Void {
                switch (gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0)) {
                    case gl.WAIT_FAILED:
                        reject();
                        break;
                    case gl.TIMEOUT_EXPIRED:
                        js.Browser.window.setTimeout(probe, interval);
                        break;
                    default:
                        resolve();
                }
            }
            js.Browser.window.setTimeout(probe, interval);
        });
    }
}