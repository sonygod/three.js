import constants.SRGBColorSpace;
import constants.LinearSRGBColorSpace;
import constants.DisplayP3ColorSpace;
import constants.LinearDisplayP3ColorSpace;
import constants.Rec709Primaries;
import constants.P3Primaries;
import constants.SRGBTransfer;
import constants.LinearTransfer;
import constants.NoColorSpace;
import math.Matrix3;

class ColorManagement {

    public static var enabled:Bool = true;

    private static var _workingColorSpace:String = LinearSRGBColorSpace;

    public static function get workingColorSpace():String {
        return _workingColorSpace;
    }

    public static function set workingColorSpace(colorSpace:String):Void {
        if (!SUPPORTED_WORKING_COLOR_SPACES.exists(colorSpace)) {
            throw 'Unsupported working color space, "' + colorSpace + '".';
        }
        _workingColorSpace = colorSpace;
    }

    public static function convert(color:Dynamic, sourceColorSpace:String, targetColorSpace:String):Dynamic {
        if (!enabled || sourceColorSpace == targetColorSpace || sourceColorSpace == null || targetColorSpace == null) {
            return color;
        }

        var sourceToReference = COLOR_SPACES[sourceColorSpace].toReference;
        var targetFromReference = COLOR_SPACES[targetColorSpace].fromReference;

        return targetFromReference(sourceToReference(color));
    }

    public static function fromWorkingColorSpace(color:Dynamic, targetColorSpace:String):Dynamic {
        return convert(color, _workingColorSpace, targetColorSpace);
    }

    public static function toWorkingColorSpace(color:Dynamic, sourceColorSpace:String):Dynamic {
        return convert(color, sourceColorSpace, _workingColorSpace);
    }

    public static function getPrimaries(colorSpace:String):Dynamic {
        return COLOR_SPACES[colorSpace].primaries;
    }

    public static function getTransfer(colorSpace:String):Dynamic {
        if (colorSpace == NoColorSpace) return LinearTransfer;
        return COLOR_SPACES[colorSpace].transfer;
    }

}

class Main {
    public static inline var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3:Matrix3 = new Matrix3().set(
        0.8224621, 0.177538, 0.0,
        0.0331941, 0.9668058, 0.0,
        0.0170827, 0.0723974, 0.9105199
    );

    public static inline var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB:Matrix3 = new Matrix3().set(
        1.2249401, -0.2249404, 0.0,
        -0.0420569, 1.0420571, 0.0,
        -0.0196376, -0.0786361, 1.0982735
    );

    public static inline var COLOR_SPACES:Map<String, Dynamic> = [
        LinearSRGBColorSpace => {
            transfer: LinearTransfer,
            primaries: Rec709Primaries,
            toReference: (color) -> color,
            fromReference: (color) -> color
        },
        SRGBColorSpace => {
            transfer: SRGBTransfer,
            primaries: Rec709Primaries,
            toReference: (color) -> color.convertSRGBToLinear(),
            fromReference: (color) -> color.convertLinearToSRGB()
        },
        LinearDisplayP3ColorSpace => {
            transfer: LinearTransfer,
            primaries: P3Primaries,
            toReference: (color) -> color.applyMatrix3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB),
            fromReference: (color) -> color.applyMatrix3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3)
        },
        DisplayP3ColorSpace => {
            transfer: SRGBTransfer,
            primaries: P3Primaries,
            toReference: (color) -> color.convertSRGBToLinear().applyMatrix3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB),
            fromReference: (color) -> color.applyMatrix3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3).convertLinearToSRGB()
        }
    ];

    public static var SUPPORTED_WORKING_COLOR_SPACES:Set<String> = new Set([LinearSRGBColorSpace, LinearDisplayP3ColorSpace]);

    public static function SRGBToLinear(c:Float):Float {
        return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
    }

    public static function LinearToSRGB(c:Float):Float {
        return (c < 0.0031308) ? c * 12.92 : 1.055 * Math.pow(c, 0.41666) - 0.055;
    }
}