import js.lib.Int8Array;
import js.lib.Uint8Array;
import js.lib.Uint8ClampedArray;
import js.lib.Int16Array;
import js.lib.Uint16Array;
import js.lib.Int32Array;
import js.lib.Uint32Array;
import js.lib.Float32Array;
import js.lib.Float64Array;
import js.Browser;
import js.lib.Promise;

class Main {

    public static function arrayMin(array: Array<Float>): Float {
        if (array.length == 0) {
            return Math.POSITIVE_INFINITY;
        }
        var min = array[0];
        for (i in 1...array.length) {
            if (array[i] < min) {
                min = array[i];
            }
        }
        return min;
    }

    public static function arrayMax(array: Array<Float>): Float {
        if (array.length == 0) {
            return Math.NEGATIVE_INFINITY;
        }
        var max = array[0];
        for (i in 1...array.length) {
            if (array[i] > max) {
                max = array[i];
            }
        }
        return max;
    }

    public static function arrayNeedsUint32(array: Array<Int>): Bool {
        for (i in array.length - 1...0 by -1) {
            if (array[i] >= 65535) {
                return true;
            }
        }
        return false;
    }

    static final TYPED_ARRAYS = {
        "Int8Array": Int8Array,
        "Uint8Array": Uint8Array,
        "Uint8ClampedArray": Uint8ClampedArray,
        "Int16Array": Int16Array,
        "Uint16Array": Uint16Array,
        "Int32Array": Int32Array,
        "Uint32Array": Uint32Array,
        "Float32Array": Float32Array,
        "Float64Array": Float64Array
    };

    public static function getTypedArray(type: String, buffer: js.lib.ArrayBuffer): Dynamic {
        return Reflect.construct(TYPED_ARRAYS[type], [buffer]);
    }

    public static function createElementNS(name: String): js.html.Element {
        return Browser.document.createElementNS("http://www.w3.org/1999/xhtml", name);
    }

    public static function createCanvasElement(): js.html.CanvasElement {
        var canvas = cast createElementNS("canvas");
        canvas.style.display = "block";
        return canvas;
    }

    static var _cache: Map<String, Bool> = new Map();

    public static function warnOnce(message: String): Void {
        if (_cache.exists(message)) {
            return;
        }
        _cache.set(message, true);
        trace('Warning: $message');
    }

    public static function probeAsync(gl: js.html.webgl.RenderingContext, sync: Dynamic, interval: Int): Promise<Void> {
        return new Promise(function(resolve, reject) {
            function probe() {
                switch (gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0)) {
                    case gl.WAIT_FAILED:
                        reject(null);
                    case gl.TIMEOUT_EXPIRED:
                        Browser.setTimeout(probe, interval);
                    default:
                        resolve(null);
                }
            }
            Browser.setTimeout(probe, interval);
        });
    }
}