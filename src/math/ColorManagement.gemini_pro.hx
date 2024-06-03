import ColorManagement.ColorSpace;
import ColorManagement.ColorSpaceType;
import ColorManagement.TransferFunction;
import ColorManagement.TransferFunctionType;
import ColorManagement.Primaries;
import ColorManagement.PrimariesType;
import ColorManagement.Matrix3;
import ColorManagement.Color;
import ColorManagement.LinearSRGBColorSpace;
import ColorManagement.SRGBColorSpace;
import ColorManagement.LinearDisplayP3ColorSpace;
import ColorManagement.DisplayP3ColorSpace;
import ColorManagement.NoColorSpace;
import ColorManagement.LinearTransfer;
import ColorManagement.SRGBTransfer;
import ColorManagement.Rec709Primaries;
import ColorManagement.P3Primaries;

class ColorManagement {

	public static enabled:Bool = true;

	private static _workingColorSpace:ColorSpaceType = LinearSRGBColorSpace;

	public static get workingColorSpace():ColorSpaceType {

		return _workingColorSpace;

	}

	public static set workingColorSpace(colorSpace:ColorSpaceType) {

		if (!SUPPORTED_WORKING_COLOR_SPACES.has(colorSpace)) {

			throw "Unsupported working color space, " + colorSpace;

		}

		_workingColorSpace = colorSpace;

	}

	public static convert(color:Color, sourceColorSpace:ColorSpaceType, targetColorSpace:ColorSpaceType):Color {

		if (!enabled || sourceColorSpace == targetColorSpace || sourceColorSpace == null || targetColorSpace == null) {

			return color;

		}

		var sourceToReference = COLOR_SPACES[sourceColorSpace].toReference;
		var targetFromReference = COLOR_SPACES[targetColorSpace].fromReference;

		return targetFromReference(sourceToReference(color));

	}

	public static fromWorkingColorSpace(color:Color, targetColorSpace:ColorSpaceType):Color {

		return convert(color, _workingColorSpace, targetColorSpace);

	}

	public static toWorkingColorSpace(color:Color, sourceColorSpace:ColorSpaceType):Color {

		return convert(color, sourceColorSpace, _workingColorSpace);

	}

	public static getPrimaries(colorSpace:ColorSpaceType):PrimariesType {

		return COLOR_SPACES[colorSpace].primaries;

	}

	public static getTransfer(colorSpace:ColorSpaceType):TransferFunctionType {

		if (colorSpace == NoColorSpace) return LinearTransfer;

		return COLOR_SPACES[colorSpace].transfer;

	}

}

enum ColorSpaceType {
	LinearSRGBColorSpace,
	SRGBColorSpace,
	LinearDisplayP3ColorSpace,
	DisplayP3ColorSpace,
	NoColorSpace;
}

enum TransferFunctionType {
	LinearTransfer,
	SRGBTransfer;
}

enum PrimariesType {
	Rec709Primaries,
	P3Primaries;
}

class ColorSpace {

	public transfer:TransferFunctionType;
	public primaries:PrimariesType;
	public toReference:Color -> Color;
	public fromReference:Color -> Color;

}

var SUPPORTED_WORKING_COLOR_SPACES = new haxe.ds.Set([LinearSRGBColorSpace, LinearDisplayP3ColorSpace]);

var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = new Matrix3().set(
	0.8224621, 0.177538, 0.0,
	0.0331941, 0.9668058, 0.0,
	0.0170827, 0.0723974, 0.9105199
);

var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = new Matrix3().set(
	1.2249401, -0.2249404, 0.0,
	-0.0420569, 1.0420571, 0.0,
	-0.0196376, -0.0786361, 1.0982735
);

var COLOR_SPACES:Map<ColorSpaceType, ColorSpace> = new Map<ColorSpaceType, ColorSpace>();
COLOR_SPACES.set(LinearSRGBColorSpace, {
	transfer: LinearTransfer,
	primaries: Rec709Primaries,
	toReference: function(color:Color) {
		return color;
	},
	fromReference: function(color:Color) {
		return color;
	}
});
COLOR_SPACES.set(SRGBColorSpace, {
	transfer: SRGBTransfer,
	primaries: Rec709Primaries,
	toReference: function(color:Color) {
		return color.convertSRGBToLinear();
	},
	fromReference: function(color:Color) {
		return color.convertLinearToSRGB();
	}
});
COLOR_SPACES.set(LinearDisplayP3ColorSpace, {
	transfer: LinearTransfer,
	primaries: P3Primaries,
	toReference: function(color:Color) {
		return color.applyMatrix3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB);
	},
	fromReference: function(color:Color) {
		return color.applyMatrix3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3);
	}
});
COLOR_SPACES.set(DisplayP3ColorSpace, {
	transfer: SRGBTransfer,
	primaries: P3Primaries,
	toReference: function(color:Color) {
		return color.convertSRGBToLinear().applyMatrix3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB);
	},
	fromReference: function(color:Color) {
		return color.applyMatrix3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3).convertLinearToSRGB();
	}
});

function SRGBToLinear(c:Float):Float {

	return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);

}

function LinearToSRGB(c:Float):Float {

	return (c < 0.0031308) ? c * 12.92 : 1.055 * (Math.pow(c, 0.41666)) - 0.055;

}