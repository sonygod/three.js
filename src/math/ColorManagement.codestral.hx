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

class ColorManagement {
    public static var enabled:Bool = true;
    private static var _workingColorSpace:Int = LinearSRGBColorSpace;

    public static function get workingColorSpace():Int {
        return _workingColorSpace;
    }

    public static function set workingColorSpace(colorSpace:Int):Void {
        if (!SUPPORTED_WORKING_COLOR_SPACES.exists(colorSpace)) {
            throw new Error("Unsupported working color space, \"" + Std.string(colorSpace) + "\".");
        }

        _workingColorSpace = colorSpace;
    }

    public static function convert(color:Color, sourceColorSpace:Int, targetColorSpace:Int):Color {
        if (enabled == false || sourceColorSpace == targetColorSpace || sourceColorSpace == null || targetColorSpace == null) {
            return color;
        }

        var sourceToReference = COLOR_SPACES.get(sourceColorSpace).toReference;
        var targetFromReference = COLOR_SPACES.get(targetColorSpace).fromReference;

        return targetFromReference(sourceToReference(color));
    }

    public static function fromWorkingColorSpace(color:Color, targetColorSpace:Int):Color {
        return convert(color, _workingColorSpace, targetColorSpace);
    }

    public static function toWorkingColorSpace(color:Color, sourceColorSpace:Int):Color {
        return convert(color, sourceColorSpace, _workingColorSpace);
    }

    public static function getPrimaries(colorSpace:Int):Primaries {
        return COLOR_SPACES.get(colorSpace).primaries;
    }

    public static function getTransfer(colorSpace:Int):Transfer {
        if (colorSpace == NoColorSpace) return LinearTransfer;

        return COLOR_SPACES.get(colorSpace).transfer;
    }
}

// Assuming Color type has convertSRGBToLinear and convertLinearToSRGB methods.
// Assuming Primaries and Transfer types are defined.

var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3:Matrix3 = new Matrix3()
    .set(0.8224621, 0.177538, 0.0,
         0.0331941, 0.9668058, 0.0,
         0.0170827, 0.0723974, 0.9105199);

var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB:Matrix3 = new Matrix3()
    .set(1.2249401, -0.2249404, 0.0,
         -0.0420569, 1.0420571, 0.0,
         -0.0196376, -0.0786361, 1.0982735);

var COLOR_SPACES:Map<Int, {transfer:Transfer, primaries:Primaries, toReference:(Color) -> Color, fromReference:(Color) -> Color}> = new Map<Int, _>();

COLOR_SPACES.set(LinearSRGBColorSpace, {
    transfer: LinearTransfer,
    primaries: Rec709Primaries,
    toReference: (color) => color,
    fromReference: (color) => color
});

COLOR_SPACES.set(SRGBColorSpace, {
    transfer: SRGBTransfer,
    primaries: Rec709Primaries,
    toReference: (color) => color.convertSRGBToLinear(),
    fromReference: (color) => color.convertLinearToSRGB()
});

COLOR_SPACES.set(LinearDisplayP3ColorSpace, {
    transfer: LinearTransfer,
    primaries: P3Primaries,
    toReference: (color) => color.applyMatrix3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB),
    fromReference: (color) => color.applyMatrix3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3)
});

COLOR_SPACES.set(DisplayP3ColorSpace, {
    transfer: SRGBTransfer,
    primaries: P3Primaries,
    toReference: (color) => color.convertSRGBToLinear().applyMatrix3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB),
    fromReference: (color) => color.applyMatrix3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3).convertLinearToSRGB()
});

var SUPPORTED_WORKING_COLOR_SPACES:Set<Int> = new Set<Int>([LinearSRGBColorSpace, LinearDisplayP3ColorSpace]);

function SRGBToLinear(c:Float):Float {
    return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
}

function LinearToSRGB(c:Float):Float {
    return (c < 0.0031308) ? c * 12.92 : 1.055 * Math.pow(c, 0.41666) - 0.055;
}