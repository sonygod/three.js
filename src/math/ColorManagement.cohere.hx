import h2d.Matrix3;

class ColorManagement {
    static public var enabled:Bool = true;
    static private var _workingColorSpace:Int = LinearSRGBColorSpace;

    static public function get workingColorSpace():Int {
        return _workingColorSpace;
    }

    static public function set workingColorSpace(colorSpace:Int):Void {
        if (!SUPPORTED_WORKING_COLOR_SPACES.has(colorSpace)) {
            throw $hxExceptions.ERangeError("Unsupported working color space, \"${colorSpace}\".");
        }
        _workingColorSpace = colorSpace;
    }

    static public function convert(color:Float, sourceColorSpace:Int, targetColorSpace:Int):Float {
        if (!enabled || sourceColorSpace == targetColorSpace || sourceColorSpace == null || targetColorSpace == null) {
            return color;
        }
        var sourceToReference = COLOR_SPACES[sourceColorSpace].toReference;
        var targetFromReference = COLOR_SPACES[targetColorSpace].fromReference;
        return targetFromReference(sourceToReference(color));
    }

    static public function fromWorkingColorSpace(color:Float, targetColorSpace:Int):Float {
        return convert(color, _workingColorSpace, targetColorSpace);
    }

    static public function toWorkingColorSpace(color:Float, sourceColorSpace:Int):Float {
        return convert(color, sourceColorSpace, _workingColorSpace);
    }

    static public function getPrimaries(colorSpace:Int):Float {
        return COLOR_SPACES[colorSpace].primaries;
    }

    static public function getTransfer(colorSpace:Int):Float {
        if (colorSpace == NoColorSpace) return LinearTransfer;
        return COLOR_SPACES[colorSpace].transfer;
    }
}

const LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = new Matrix3(
    0.8224621, 0.177538, 0.0,
    0.0331941, 0.9668058, 0.0,
    0.0170827, 0.0723974, 0.9105199
);

const LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = new Matrix3(
    1.2249401, -0.2249404, 0.0,
    -0.0420569, 1.0420571, 0.0,
    -0.0196376, -0.0786361, 1.0982735
);

const COLOR_SPACES = {
    LinearSRGBColorSpace: {
        transfer: LinearTransfer,
        primaries: Rec709Primaries,
        toReference: function(color:Float) { return color; },
        fromReference: function(color:Float) { return color; }
    },
    SRGBColorSpace: {
        transfer: SRGBTransfer,
        primaries: Rec709Primaries,
        toReference: function(color:Float) { return SRGBToLinear(color); },
        fromReference: function(color:Float) { return LinearToSRGB(color); }
    },
    LinearDisplayP3ColorSpace: {
        transfer: LinearTransfer,
        primaries: P3Primaries,
        toReference: function(color:Float) { return LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.transformVector(color); },
        fromReference: function(color:Float) { return LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.transformVector(color); }
    },
    DisplayP3ColorSpace: {
        transfer: SRGBTransfer,
        primaries: P3Primaries,
        toReference: function(color:Float) { return LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.transformVector(SRGBToLinear(color)); },
        fromReference: function(color:Float) { return LinearToSRGB(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.transformVector(color)); }
    }
};

const SUPPORTED_WORKING_COLOR_SPACES = new Set([LinearSRGBColorSpace, LinearDisplayP3ColorSpace]);

function SRGBToLinear(c:Float):Float {
    return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
}

function LinearToSRGB(c:Float):Float {
    return (c < 0.0031308) ? c * 12.92 : 1.055 * Math.pow(c, 0.41666) - 0.055;
}