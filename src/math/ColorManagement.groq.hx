package three.math;

import haxe.ds.Set;
import three.constants.ColorSpaceConstants;

class ColorManagement {
    public static var enabled:Bool = true;

    private var _workingColorSpace:ColorSpaceConstants;

    public var workingColorSpace(get, set):ColorSpaceConstants;

    private function get_workingColorSpace():ColorSpaceConstants {
        return _workingColorSpace;
    }

    private function set_workingColorSpace(colorSpace:ColorSpaceConstants):ColorSpaceConstants {
        if (!SUPPORTED_WORKING_COLOR_SPACES.has(colorSpace)) {
            throw new Error('Unsupported working color space, "${colorSpace}".');
        }
        _workingColorSpace = colorSpace;
        return colorSpace;
    }

    private static var COLOR_SPACES:Array<ColorSpaceDefinition> = [
        LinearSRGBColorSpace => {
            transfer: LinearTransfer,
            primaries: Rec709Primaries,
            toReference: function(color) return color,
            fromReference: function(color) return color
        },
        SRGBColorSpace => {
            transfer: SRGBTransfer,
            primaries: Rec709Primaries,
            toReference: function(color) return color.convertSRGBToLinear(),
            fromReference: function(color) return color.convertLinearToSRGB()
        },
        LinearDisplayP3ColorSpace => {
            transfer: LinearTransfer,
            primaries: P3Primaries,
            toReference: function(color) return color.applyMatrix3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB),
            fromReference: function(color) return color.applyMatrix3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3)
        },
        DisplayP3ColorSpace => {
            transfer: SRGBTransfer,
            primaries: P3Primaries,
            toReference: function(color) return color.convertSRGBToLinear().applyMatrix3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB),
            fromReference: function(color) return color.applyMatrix3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3).convertLinearToSRGB()
        }
    ];

    private static var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = new Matrix3([
        0.8224621, 0.177538, 0.0,
        0.0331941, 0.9668058, 0.0,
        0.0170827, 0.0723974, 0.9105199
    ]);

    private static var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = new Matrix3([
        1.2249401, -0.2249404, 0.0,
        -0.0420569, 1.0420571, 0.0,
        -0.0196376, -0.0786361, 1.0982735
    ]);

    private static var SUPPORTED_WORKING_COLOR_SPACES:Set<ColorSpaceConstants> = [LinearSRGBColorSpace, LinearDisplayP3ColorSpace];

    public function new() {}

    public function convert(color, sourceColorSpace:ColorSpaceConstants, targetColorSpace:ColorSpaceConstants):Dynamic {
        if (!enabled || sourceColorSpace == targetColorSpace || !sourceColorSpace || !targetColorSpace) {
            return color;
        }

        var sourceToReference = COLOR_SPACES[sourceColorSpace].toReference;
        var targetFromReference = COLOR_SPACES[targetColorSpace].fromReference;

        return targetFromReference(sourceToReference(color));
    }

    public function fromWorkingColorSpace(color, targetColorSpace:ColorSpaceConstants):Dynamic {
        return convert(color, _workingColorSpace, targetColorSpace);
    }

    public function toWorkingColorSpace(color, sourceColorSpace:ColorSpaceConstants):Dynamic {
        return convert(color, sourceColorSpace, _workingColorSpace);
    }

    public function getPrimaries(colorSpace:ColorSpaceConstants):Dynamic {
        return COLOR_SPACES[colorSpace].primaries;
    }

    public function getTransfer(colorSpace:ColorSpaceConstants):Dynamic {
        if (colorSpace == NoColorSpace) return LinearTransfer;
        return COLOR_SPACES[colorSpace].transfer;
    }
}

class ColorSpaceDefinition {
    public var transfer:Dynamic;
    public var primaries:Dynamic;
    public var toReference:Dynamic;
    public var fromReference:Dynamic;
}

// Helper functions
public function SRGBToLinear(c:Float):Float {
    return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
}

public function LinearToSRGB(c:Float):Float {
    return (c < 0.0031308) ? c * 12.92 : 1.055 * Math.pow(c, 0.41666) - 0.055;
}