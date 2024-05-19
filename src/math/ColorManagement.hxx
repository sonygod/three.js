import three.js.src.constants.*;
import three.js.src.math.Matrix3;

class ColorManagement {

    static var enabled:Bool = true;
    static var _workingColorSpace:String = LinearSRGBColorSpace;

    static function get workingColorSpace():String {
        return _workingColorSpace;
    }

    static function set workingColorSpace(colorSpace:String):Void {
        if (!SUPPORTED_WORKING_COLOR_SPACES.has(colorSpace)) {
            throw 'Unsupported working color space, "' + colorSpace + '".';
        }
        _workingColorSpace = colorSpace;
    }

    static function convert(color:Dynamic, sourceColorSpace:String, targetColorSpace:String):Dynamic {
        if (!enabled || sourceColorSpace == targetColorSpace || sourceColorSpace == null || targetColorSpace == null) {
            return color;
        }
        var sourceToReference = COLOR_SPACES[sourceColorSpace].toReference;
        var targetFromReference = COLOR_SPACES[targetColorSpace].fromReference;
        return targetFromReference(sourceToReference(color));
    }

    static function fromWorkingColorSpace(color:Dynamic, targetColorSpace:String):Dynamic {
        return convert(color, _workingColorSpace, targetColorSpace);
    }

    static function toWorkingColorSpace(color:Dynamic, sourceColorSpace:String):Dynamic {
        return convert(color, sourceColorSpace, _workingColorSpace);
    }

    static function getPrimaries(colorSpace:String):Dynamic {
        return COLOR_SPACES[colorSpace].primaries;
    }

    static function getTransfer(colorSpace:String):Dynamic {
        if (colorSpace == NoColorSpace) return LinearTransfer;
        return COLOR_SPACES[colorSpace].transfer;
    }

}

static function SRGBToLinear(c:Float):Float {
    return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
}

static function LinearToSRGB(c:Float):Float {
    return (c < 0.0031308) ? c * 12.92 : 1.055 * (Math.pow(c, 0.41666)) - 0.055;
}