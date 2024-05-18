package three.math;

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
    static var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = new Matrix3([
        0.8224621, 0.177538, 0.0,
        0.0331941, 0.9668058, 0.0,
        0.0170827, 0.0723974, 0.9105199
    ]);

    static var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = new Matrix3([
        1.2249401, -0.2249404, 0.0,
        -0.0420569, 1.0420571, 0.0,
        -0.0196376, -0.0786361, 1.0982735
    ]);

    /**
     * Defines supported color spaces by transfer function and primaries,
     * and provides conversions to/from the Linear-sRGB reference space.
     */
    static var COLOR_SPACES = [
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

    static var SUPPORTED_WORKING_COLOR_SPACES = [LinearSRGBColorSpace, LinearDisplayP3ColorSpace];

    public var enabled:Bool = true;

    private var _workingColorSpace:ColorSpace = LinearSRGBColorSpace;

    public var workingColorSpace(get, set):ColorSpace;

    function get_workingColorSpace():ColorSpace {
        return _workingColorSpace;
    }

    function set_workingColorSpace(colorSpace:ColorSpace) {
        if (!SUPPORTED_WORKING_COLOR_SPACES.has(colorSpace)) {
            throw new Error('Unsupported working color space, "${colorSpace}"');
        }
        _workingColorSpace = colorSpace;
    }

    public function convert(color:Color, sourceColorSpace:ColorSpace, targetColorSpace:ColorSpace):Color {
        if (!enabled || sourceColorSpace == targetColorSpace || !sourceColorSpace || !targetColorSpace) {
            return color;
        }
        var sourceToReference = COLOR_SPACES[sourceColorSpace].toReference;
        var targetFromReference = COLOR_SPACES[targetColorSpace].fromReference;
        return targetFromReference(sourceToReference(color));
    }

    public function fromWorkingColorSpace(color:Color, targetColorSpace:ColorSpace):Color {
        return convert(color, _workingColorSpace, targetColorSpace);
    }

    public function toWorkingColorSpace(color:Color, sourceColorSpace:ColorSpace):Color {
        return convert(color, sourceColorSpace, _workingColorSpace);
    }

    public function getPrimaries(colorSpace:ColorSpace):Array<Float> {
        return COLOR_SPACES[colorSpace].primaries;
    }

    public function getTransfer(colorSpace:ColorSpace):TransferFunction {
        if (colorSpace == NoColorSpace) return LinearTransfer;
        return COLOR_SPACES[colorSpace].transfer;
    }
}

// Helper functions
public function SRGBToLinear(c:Float):Float {
    return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
}

public function LinearToSRGB(c:Float):Float {
    return (c < 0.0031308) ? c * 12.92 : 1.055 * Math.pow(c, 0.41666) - 0.055;
}