package three.utils;

import js.html.Document;
import js.html.CanvasElement;
import js.Browser.console;

class Utils {
    public static function arrayMin(array:Array<Float>):Float {
        if (array.length === 0) return Math.POSITIVE_INFINITY;
        var min = array[0];
        for (i in 1...array.length) {
            if (array[i] < min) min = array[i];
        }
        return min;
    }

    public static function arrayMax(array:Array<Float>):Float {
        if (array.length === 0) return Math.NEGATIVE_INFINITY;
        var max = array[0];
        for (i in 1...array.length) {
            if (array[i] > max) max = array[i];
        }
        return max;
    }

    public static function arrayNeedsUint32(array:Array<Float>):Bool {
        for (i in array.length - 1...0) {
            if (array[i] >= 65535) return true;
        }
        return false;
    }

    public static var TYPED_ARRAYS = {
        Int8Array: js.lib.Int8Array,
        Uint8Array: js.lib.Uint8Array,
        Uint8ClampedArray: js.lib.Uint8ClampedArray,
        Int16Array: js.lib.Int16Array,
        Uint16Array: js.lib.Uint16Array,
        Int32Array: js.lib.Int32Array,
        Uint32Array: js.lib.Uint32Array,
        Float32Array: js.lib.Float32Array,
        Float64Array: js.lib.Float64Array
    };

    public static function getTypedArray(type:String, buffer:Dynamic):Dynamic {
        return new TYPED_ARRAYS[type](buffer);
    }

    public static function createElementNS(name:String):Dynamic {
        return Document.createElementNS('http://www.w3.org/1999/xhtml', name);
    }

    public static function createCanvasElement():CanvasElement {
        var canvas:CanvasElement = createElementNS('canvas');
        canvas.style.display = 'block';
        return canvas;
    }

    private static var _cache:Map<String, Bool> = new Map();

    public static function warnOnce(message:String):Void {
        if (_cache.exists(message)) return;
        _cache.set(message, true);
        console.warn(message);
    }

    public static function probeAsync(gl:Dynamic, sync:Dynamic, interval:Int):js.lib.Promise<Void> {
        return new js.lib.Promise(function(resolve, reject) {
            function probe() {
                switch (gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0)) {
                    case gl.WAIT_FAILED:
                        reject();
                        break;
                    case gl.TIMEOUT_EXPIRED:
                        haxe.Timer.delay(probe, interval);
                        break;
                    default:
                        resolve();
                }
            }
            haxe.Timer.delay(probe, interval);
        });
    }
}