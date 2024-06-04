import haxe.io.Bytes;
import js.html.CanvasElement;
import js.html.Document;
import js.html.Element;
import js.html.Window;
import js.html.webgl.WebGLRenderingContext;
import js.html.webgl.WebGLSync;

class TypedArrays {
  public static var Int8Array:Class<Int8Array> = Int8Array;
  public static var Uint8Array:Class<Uint8Array> = Uint8Array;
  public static var Uint8ClampedArray:Class<Uint8ClampedArray> = Uint8ClampedArray;
  public static var Int16Array:Class<Int16Array> = Int16Array;
  public static var Uint16Array:Class<Uint16Array> = Uint16Array;
  public static var Int32Array:Class<Int32Array> = Int32Array;
  public static var Uint32Array:Class<Uint32Array> = Uint32Array;
  public static var Float32Array:Class<Float32Array> = Float32Array;
  public static var Float64Array:Class<Float64Array> = Float64Array;
}

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
    for (i in (array.length - 1)...0) {
      if (array[i] >= 65535) return true;
    }
    return false;
  }

  public static function getTypedArray(type:String, buffer:Bytes):Dynamic {
    return Type.createInstance(TypedArrays.get(type), [buffer]);
  }

  public static function createElementNS(name:String):Element {
    return Document.window.document.createElementNS('http://www.w3.org/1999/xhtml', name);
  }

  public static function createCanvasElement():CanvasElement {
    var canvas = createElementNS('canvas');
    canvas.style.display = 'block';
    return canvas;
  }

  static var _cache:Map<String, Bool> = new Map();

  public static function warnOnce(message:String):Void {
    if (_cache.exists(message)) return;
    _cache.set(message, true);
    console.warn(message);
  }

  public static function probeAsync(gl:WebGLRenderingContext, sync:WebGLSync, interval:Int):Dynamic {
    return new Promise((resolve, reject) -> {
      function probe() {
        switch (gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0)) {
          case gl.WAIT_FAILED:
            reject();
          case gl.TIMEOUT_EXPIRED:
            Window.setTimeout(probe, interval);
          default:
            resolve();
        }
      }
      Window.setTimeout(probe, interval);
    });
  }
}

export class Utils {
  static inline var arrayMin = Utils.arrayMin;
  static inline var arrayMax = Utils.arrayMax;
  static inline var arrayNeedsUint32 = Utils.arrayNeedsUint32;
  static inline var getTypedArray = Utils.getTypedArray;
  static inline var createElementNS = Utils.createElementNS;
  static inline var createCanvasElement = Utils.createCanvasElement;
  static inline var warnOnce = Utils.warnOnce;
  static inline var probeAsync = Utils.probeAsync;
}