package three.math;

import three.constants.Constants;

class ColorManagement {
    public static var enabled:Bool = true;

    private static var _workingColorSpace:ColorSpace = LinearSRGBColorSpace;

    public static var workingColorSpace(get, set):ColorSpace;

    private static function get_workingColorSpace():ColorSpace {
        return _workingColorSpace;
    }

    private static function set_workingColorSpace(colorSpace:ColorSpace):ColorSpace {
        if (!SUPPORTED_WORKING_COLOR_SPACES.has(colorSpace)) {
            throw new Error('Unsupported working color space, "${colorSpace}"');
        }
        _workingColorSpace = colorSpace;
        return colorSpace;
    }

    private static var COLOR_SPACES:Map<ColorSpace, ColorSpaceInfo> = [
        LinearSRGBColorSpace => {
            transfer: LinearTransfer,
            primaries: Rec709Primaries,
            toReference: function(color:Color) return color,
            fromReference: function(color:Color) return color,
        },
        SRGBColorSpace => {
            transfer: SRGBTransfer,
            primaries: Rec709Primaries,
            toReference: function(color:Color) return color.convertSRGBToLinear(),
            fromReference: function(color:Color) return color.convertLinearToSRGB(),
        },
        LinearDisplayP3ColorSpace => {
            transfer: LinearTransfer,
            primaries: P3Primaries,
            toReference: function(color:Color) return color.applyMatrix3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB),
            fromReference: function(color:Color) return color.applyMatrix3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3),
        },
        DisplayP3ColorSpace => {
            transfer: SRGBTransfer,
            primaries: P3Primaries,
            toReference: function(color:Color) return color.convertSRGBToLinear().applyMatrix3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB),
            fromReference: function(color:Color) return color.applyMatrix3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3).convertLinearToSRGB(),
        },
    ];

    private static var SUPPORTED_WORKING_COLOR_SPACES:EReg = ~/^(LinearSRGBColorSpace|LinearDisplayP3ColorSpace)$/;

    public static function convert(color:Color, sourceColorSpace:ColorSpace, targetColorSpace:ColorSpace):Color {
        if (!enabled || sourceColorSpace == targetColorSpace || sourceColorSpace == null || targetColorSpace == null) {
            return color;
        }
        var sourceToReference = COLOR_SPACES[sourceColorSpace].toReference;
        var targetFromReference = COLOR_SPACES[targetColorSpace].fromReference;
        return targetFromReference(sourceToReference(color));
    }

    public static function fromWorkingColorSpace(color:Color, targetColorSpace:ColorSpace):Color {
        return convert(color, _workingColorSpace, targetColorSpace);
    }

    public static function toWorkingColorSpace(color:Color, sourceColorSpace:ColorSpace):Color {
        return convert(color, sourceColorSpace, _workingColorSpace);
    }

    public static function getPrimaries(colorSpace:ColorSpace):Primaries {
        return COLOR_SPACES[colorSpace].primaries;
    }

    public static function getTransfer(colorSpace:ColorSpace):Transfer {
        if (colorSpace == NoColorSpace) return LinearTransfer;
        return COLOR_SPACES[colorSpace].transfer;
    }
}

private class ColorSpaceInfo {
    public var transfer:Transfer;
    public var primaries:Primaries;
    public var toReference:Color->Color;
    public var fromReference:Color->Color;
}

typedef ColorSpace = String;
typedef Transfer = String;
typedef Primaries = String;

private static var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3:Matrix3 = new Matrix3([
    0.8224621, 0.177538, 0.0,
    0.0331941, 0.9668058, 0.0,
    0.0170827, 0.0723974, 0.9105199,
]);

private static var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB:Matrix3 = new Matrix3([
    1.2249401, -0.2249404, 0.0,
    -0.0420569, 1.0420571, 0.0,
    -0.0196376, -0.0786361, 1.0982735,
]);

public static function SRGBToLinear(c:Float):Float {
    return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
}

public static function LinearToSRGB(c:Float):Float {
    return (c < 0.0031308) ? c * 12.92 : 1.055 * Math.pow(c, 0.41666) - 0.055;
}