import haxe.io.Bytes;
import js.html.Element;
import js.html.Window;
import js.html.CanvasElement;
import js.html.Document;
import js.html.WebGLRenderingContext;
import js.html.WebGLSync;
import js.Promise;

class Utils {
    public static function arrayMin(array:Array<Int>):Int {
        if (array.length == 0) return Int.MAX_VALUE;
        var min = array[0];
        for (i in 1...array.length) {
            if (array[i] < min) min = array[i];
        }
        return min;
    }

    public static function arrayMax(array:Array<Int>):Int {
        if (array.length == 0) return Int.MIN_VALUE;
        var max = array[0];
        for (i in 1...array.length) {
            if (array[i] > max) max = array[i];
        }
        return max;
    }

    public static function arrayNeedsUint32(array:Array<Int>):Bool {
        for (i in array.length - 1...0..-1) {
            if (array[i] >= 65535) return true;
        }
        return false;
    }

    private static var TYPED_ARRAYS = {
        Int8Array: Int8Array,
        Uint8Array: Uint8Array,
        Uint8ClampedArray: Uint8ClampedArray,
        Int16Array: Int16Array,
        Uint16Array: Uint16Array,
        Int32Array: Int32Array,
        Uint32Array: Uint32Array,
        Float32Array: Float32Array,
        Float64Array: Float64Array
    };

    public static function getTypedArray(type:String, buffer:Bytes):Dynamic {
        return new TYPED_ARRAYS[type](buffer);
    }

    public static function createElementNS(name:String):Element {
        return Document.document.createElementNS('http://www.w3.org/1999/xhtml', name);
    }

    public static function createCanvasElement():CanvasElement {
        var canvas = createElementNS('canvas');
        canvas.style.display = 'block';
        return canvas;
    }

    private static var _cache = {};

    public static function warnOnce(message:String) {
        if (message in _cache) return;
        _cache[message] = true;
        Window.console.warn(message);
    }

    public static function probeAsync(gl:WebGLRenderingContext, sync:WebGLSync, interval:Int):Promise<Dynamic> {
        return new Promise(function(resolve, reject) {
            function probe() {
                switch (gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0)) {
                    case gl.WAIT_FAILED:
                        reject();
                        break;
                    case gl.TIMEOUT_EXPIRED:
                        setTimeout(probe, interval);
                        break;
                    default:
                        resolve();
                }
            }
            setTimeout(probe, interval);
        });
    }
}