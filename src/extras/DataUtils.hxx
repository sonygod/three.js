import js.Browser;

class DataUtils {
    static var _tables:Tables;

    static function _generateTables():Tables {
        // ... 省略代码 ...
    }

    static function toHalfFloat(val:Float):Int {
        // ... 省略代码 ...
    }

    static function fromHalfFloat(val:Int):Float {
        // ... 省略代码 ...
    }
}

class Tables {
    var floatView:Float32Array;
    var uint32View:Uint32Array;
    var baseTable:Uint32Array;
    var shiftTable:Uint32Array;
    var mantissaTable:Uint32Array;
    var exponentTable:Uint32Array;
    var offsetTable:Uint32Array;
}

class MathUtils {
    static function clamp(val:Float, min:Float, max:Float):Float {
        return Math.max(min, Math.min(max, val));
    }
}