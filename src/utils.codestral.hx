import js.Browser;

class Utils {
    public static function arrayMin(array: Array<Float>): Float {
        if (array.length == 0) return Float.POSITIVE_INFINITY;

        var min: Float = array[0];

        for (i in 1...array.length) {
            if (array[i] < min) min = array[i];
        }

        return min;
    }

    public static function arrayMax(array: Array<Float>): Float {
        if (array.length == 0) return Float.NEGATIVE_INFINITY;

        var max: Float = array[0];

        for (i in 1...array.length) {
            if (array[i] > max) max = array[i];
        }

        return max;
    }

    public static function arrayNeedsUint32(array: Array<Int>): Bool {
        for (i in (array.length - 1)...0) {
            if (array[i] >= 65535) return true;
        }

        return false;
    }

    public static function getTypedArray(type: String, buffer: js.html.ArrayBuffer): Dynamic {
        switch (type) {
            case "Int8Array": return js.html.ArrayBufferView.createInt8(buffer);
            case "Uint8Array": return js.html.ArrayBufferView.createUint8(buffer);
            case "Uint8ClampedArray": return js.html.ArrayBufferView.createUint8Clamped(buffer);
            case "Int16Array": return js.html.ArrayBufferView.createInt16(buffer);
            case "Uint16Array": return js.html.ArrayBufferView.createUint16(buffer);
            case "Int32Array": return js.html.ArrayBufferView.createInt32(buffer);
            case "Uint32Array": return js.html.ArrayBufferView.createUint32(buffer);
            case "Float32Array": return js.html.ArrayBufferView.createFloat32(buffer);
            case "Float64Array": return js.html.ArrayBufferView.createFloat64(buffer);
            default: throw "Invalid type";
        }
    }

    public static function warnOnce(message: String): Void {
        if (!Browser.window.hasOwnProperty(message)) {
            Browser.window.setProperty(message, true);
            Browser.console.log(message);
        }
    }
}