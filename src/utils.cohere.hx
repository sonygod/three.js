function arrayMin(array:Array<Int>):Int {
    if (array.length == 0) return Int.POSITIVE_INFINITY;
    var min = array[0];
    for (i in 1...array.length) {
        if (array[i] < min) min = array[i];
    }
    return min;
}

function arrayMax(array:Array<Int>):Int {
    if (array.length == 0) return Int.NEGATIVE_INFINITY;
    var max = array[0];
    for (i in 1...array.length) {
        if (array[i] > max) max = array[i];
    }
    return max;
}

function arrayNeedsUint32(array:Array<Int>):Bool {
    for (i in array.length-1...-1) {
        if (array[i] >= 65535) return true;
    }
    return false;
}

typedef TypedArrays = {
    Int8Array:Int8Array,
    Uint8Array:Uint8Array,
    Uint8ClampedArray:Uint8ClampedArray,
    Int16Array:Int16Array,
    Uint16Array:Uint16Array,
    Int32Array:Int32Array,
    Uint32Array:Uint32Array,
    Float32Array:Float32Array,
    Float64Array:Float64Array
}

var TYPED_ARRAYS:TypedArrays = {
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

function getTypedArray(type:String, buffer:ArrayBuffer):Array<Dynamic> {
    return TYPED_ARRAYS[type](buffer);
}

function createElementNS(name:String):HtmlElement {
    return untyped HtmlElement(Html.createDocument('http://www.w3.org/1999/xhtml', name));
}

function createCanvasElement():HtmlCanvasElement {
    var canvas = createElementNS('canvas') as HtmlCanvasElement;
    canvas.style.display = 'block';
    return canvas;
}

var _cache:Map<String, Bool> = new Map();

function warnOnce(message:String):Void {
    if (_cache.exists(message)) return;
    _cache[message] = true;
    trace('WARNING: ' + message);
}

function probeAsync(gl:Gl, sync:GlSync, interval:Int):Future<Void> {
    return Future.async(function(complete, error) {
        function probe():Void {
            switch(gl.clientWaitSync(sync, Gl.SYNC_FLUSH_COMMANDS_BIT, 0)) {
                case Gl.WAIT_FAILED:
                    error();
                    break;
                case Gl.TIMEOUT_EXPIRED:
                    untyped setTimeout(probe, interval);
                    break;
                default:
                    complete();
            }
        }
        untyped setTimeout(probe, interval);
    });
}