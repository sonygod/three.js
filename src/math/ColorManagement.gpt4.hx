import three.constants.SRGBColorSpace;
import three.constants.LinearSRGBColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.Rec709Primaries;
import three.constants.P3Primaries;
import three.constants.SRGBTransfer;
import three.constants.LinearTransfer;
import three.constants.NoColorSpace;
import three.math.Matrix3;

/**
 * Matrices converting P3 <-> Rec. 709 primaries, without gamut mapping
 * or clipping. Based on W3C specifications for sRGB and Display P3,
 * and ICC specifications for the D50 connection space. Values in/out
 * are _linear_ sRGB and _linear_ Display P3.
 *
 * Note that both sRGB and Display P3 use the sRGB transfer functions.
 *
 * Reference:
 * - http://www.russellcottrell.com/photo/matrixCalculator.htm
 */
class ColorManagement {
    public static var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3:Matrix3 = new Matrix3().set(
        0.8224621, 0.177538, 0.0,
        0.0331941, 0.9668058, 0.0,
        0.0170827, 0.0723974, 0.9105199
    );

    public static var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB:Matrix3 = new Matrix3().set(
        1.2249401, -0.2249404, 0.0,
        -0.0420569, 1.0420571, 0.0,
        -0.0196376, -0.0786361, 1.0982735
    );

    public static var COLOR_SPACES:Map<String, Dynamic> = [
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

    public static var SUPPORTED_WORKING_COLOR_SPACES:Set<String> = [
        LinearSRGBColorSpace, LinearDisplayP3ColorSpace
    ];

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

        var sourceToReference = COLOR_SPACES.get(sourceColorSpace).toReference;
        var targetFromReference = COLOR_SPACES.get(targetColorSpace).fromReference;

        return targetFromReference(sourceToReference(color));
    }

    public static function fromWorkingColorSpace(color:Dynamic, targetColorSpace:String):Dynamic {
        return convert(color, _workingColorSpace, targetColorSpace);
    }

    public static function toWorkingColorSpace(color:Dynamic, sourceColorSpace:String):Dynamic {
        return convert(color, sourceColorSpace, _workingColorSpace);
    }

    public static function getPrimaries(colorSpace:String):Dynamic {
        return COLOR_SPACES.get(colorSpace).primaries;
    }

    public static function getTransfer(colorSpace:String):Dynamic {
        if (colorSpace == NoColorSpace) return LinearTransfer;
        return COLOR_SPACES.get(colorSpace).transfer;
    }

    public static function SRGBToLinear(c:Float):Float {
        return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
    }

    public static function LinearToSRGB(c:Float):Float {
        return (c < 0.0031308) ? c * 12.92 : 1.055 * Math.pow(c, 0.41666) - 0.055;
    }
}