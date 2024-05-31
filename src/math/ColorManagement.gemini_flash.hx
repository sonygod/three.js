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

class LinearSRGBToDisplayP3Matrix extends Matrix3 {
	public function new() {
		super();
		this.set(0.8224621, 0.177538, 0.0,
			0.0331941, 0.9668058, 0.0,
			0.0170827, 0.0723974, 0.9105199);
	}
}

class DisplayP3ToLinearSRGBMatrix extends Matrix3 {
	public function new() {
		super();
		this.set(1.2249401, -0.2249404, 0.0,
			-0.0420569, 1.0420571, 0.0,
			-0.0196376, -0.0786361, 1.0982735);
	}
}

/**
 * Defines supported color spaces by transfer function and primaries,
 * and provides conversions to/from the Linear-sRGB reference space.
 */
private var COLOR_SPACES = {
	LinearSRGBColorSpace: {
		transfer: LinearTransfer,
		primaries: Rec709Primaries,
		toReference: (color) -> color,
		fromReference: (color) -> color,
	},
	SRGBColorSpace: {
		transfer: SRGBTransfer,
		primaries: Rec709Primaries,
		toReference: (color) -> color.convertSRGBToLinear(),
		fromReference: (color) -> color.convertLinearToSRGB(),
	},
	LinearDisplayP3ColorSpace: {
		transfer: LinearTransfer,
		primaries: P3Primaries,
		toReference: (color) -> color.applyMatrix3(new DisplayP3ToLinearSRGBMatrix()),
		fromReference: (color) -> color.applyMatrix3(new LinearSRGBToDisplayP3Matrix()),
	},
	DisplayP3ColorSpace: {
		transfer: SRGBTransfer,
		primaries: P3Primaries,
		toReference: (color) -> color.convertSRGBToLinear().applyMatrix3(new DisplayP3ToLinearSRGBMatrix()),
		fromReference: (color) -> color.applyMatrix3(new LinearSRGBToDisplayP3Matrix()).convertLinearToSRGB(),
	},
};

private var SUPPORTED_WORKING_COLOR_SPACES = new haxe.ds.Set([LinearSRGBColorSpace, LinearDisplayP3ColorSpace]);

class ColorManagement {
	public static var enabled:Bool = true;

	private static var _workingColorSpace:Int = LinearSRGBColorSpace;

	public static function get workingColorSpace():Int {
		return _workingColorSpace;
	}

	public static function set workingColorSpace(colorSpace:Int) {
		if (!SUPPORTED_WORKING_COLOR_SPACES.has(colorSpace)) {
			throw "Unsupported working color space, " + colorSpace;
		}
		_workingColorSpace = colorSpace;
	}

	public static function convert(color:Dynamic, sourceColorSpace:Int, targetColorSpace:Int):Dynamic {
		if (!enabled || sourceColorSpace == targetColorSpace || sourceColorSpace == null || targetColorSpace == null) {
			return color;
		}
		var sourceToReference = COLOR_SPACES[sourceColorSpace].toReference;
		var targetFromReference = COLOR_SPACES[targetColorSpace].fromReference;
		return targetFromReference(sourceToReference(color));
	}

	public static function fromWorkingColorSpace(color:Dynamic, targetColorSpace:Int):Dynamic {
		return convert(color, _workingColorSpace, targetColorSpace);
	}

	public static function toWorkingColorSpace(color:Dynamic, sourceColorSpace:Int):Dynamic {
		return convert(color, sourceColorSpace, _workingColorSpace);
	}

	public static function getPrimaries(colorSpace:Int):Dynamic {
		return COLOR_SPACES[colorSpace].primaries;
	}

	public static function getTransfer(colorSpace:Int):Dynamic {
		if (colorSpace == NoColorSpace) {
			return LinearTransfer;
		}
		return COLOR_SPACES[colorSpace].transfer;
	}
}

public function SRGBToLinear(c:Float):Float {
	return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
}

public function LinearToSRGB(c:Float):Float {
	return (c < 0.0031308) ? c * 12.92 : 1.055 * (Math.pow(c, 0.41666)) - 0.055;
}