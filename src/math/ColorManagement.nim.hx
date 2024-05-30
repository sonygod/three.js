import Matrix3.Matrix3;
import three.constants.SRGBColorSpace;
import three.constants.LinearSRGBColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.Rec709Primaries;
import three.constants.P3Primaries;
import three.constants.SRGBTransfer;
import three.constants.LinearTransfer;
import three.constants.NoColorSpace;

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

var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = new Matrix3(
	0.8224621, 0.177538, 0.0,
	0.0331941, 0.9668058, 0.0,
	0.0170827, 0.0723974, 0.9105199
);

var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = new Matrix3(
	1.2249401, - 0.2249404, 0.0,
	- 0.0420569, 1.0420571, 0.0,
	- 0.0196376, - 0.0786361, 1.0982735
);

/**
 * Defines supported color spaces by transfer function and primaries,
 * and provides conversions to/from the Linear-sRGB reference space.
 */
var COLOR_SPACES = {
	[ LinearSRGBColorSpace ]: {
		transfer: LinearTransfer,
		primaries: Rec709Primaries,
		toReference: function( color ) return color;,
		fromReference: function( color ) return color;,
	},
	[ SRGBColorSpace ]: {
		transfer: SRGBTransfer,
		primaries: Rec709Primaries,
		toReference: function( color ) return color.convertSRGBToLinear();,
		fromReference: function( color ) return color.convertLinearToSRGB();,
	},
	[ LinearDisplayP3ColorSpace ]: {
		transfer: LinearTransfer,
		primaries: P3Primaries,
		toReference: function( color ) return color.applyMatrix3( LINEAR_DISPLAY_P3_TO_LINEAR_SRGB );,
		fromReference: function( color ) return color.applyMatrix3( LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 );,
	},
	[ DisplayP3ColorSpace ]: {
		transfer: SRGBTransfer,
		primaries: P3Primaries,
		toReference: function( color ) return color.convertSRGBToLinear().applyMatrix3( LINEAR_DISPLAY_P3_TO_LINEAR_SRGB );,
		fromReference: function( color ) return color.applyMatrix3( LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 ).convertLinearToSRGB();,
	},
};

var SUPPORTED_WORKING_COLOR_SPACES = new Set<Dynamic>( [ LinearSRGBColorSpace, LinearDisplayP3ColorSpace ] );

class ColorManagement {

	public static var enabled:Bool = true;

	private static var _workingColorSpace:Dynamic = LinearSRGBColorSpace;

	public static function get workingColorSpace() {

		return _workingColorSpace;

	}

	public static function set workingColorSpace( colorSpace:Dynamic ) {

		if ( ! SUPPORTED_WORKING_COLOR_SPACES.has( colorSpace ) ) {

			throw new Error( "Unsupported working color space, " + colorSpace + "." );

		}

		_workingColorSpace = colorSpace;

	}

	public static function convert( color:Dynamic, sourceColorSpace:Dynamic, targetColorSpace:Dynamic ):Dynamic {

		if ( enabled == false || sourceColorSpace == targetColorSpace || ! sourceColorSpace || ! targetColorSpace ) {

			return color;

		}

		var sourceToReference = COLOR_SPACES[ sourceColorSpace ].toReference;
		var targetFromReference = COLOR_SPACES[ targetColorSpace ].fromReference;

		return targetFromReference( sourceToReference( color ) );

	}

	public static function fromWorkingColorSpace( color:Dynamic, targetColorSpace:Dynamic ):Dynamic {

		return convert( color, _workingColorSpace, targetColorSpace );

	}

	public static function toWorkingColorSpace( color:Dynamic, sourceColorSpace:Dynamic ):Dynamic {

		return convert( color, sourceColorSpace, _workingColorSpace );

	}

	public static function getPrimaries( colorSpace:Dynamic ):Dynamic {

		return COLOR_SPACES[ colorSpace ].primaries;

	}

	public static function getTransfer( colorSpace:Dynamic ):Dynamic {

		if ( colorSpace == NoColorSpace ) return LinearTransfer;

		return COLOR_SPACES[ colorSpace ].transfer;

	}

}

public static function SRGBToLinear( c:Float ) {

	return ( c < 0.04045 ) ? c * 0.0773993808 : Math.pow( c * 0.9478672986 + 0.0521327014, 2.4 );

}

public static function LinearToSRGB( c:Float ) {

	return ( c < 0.0031308 ) ? c * 12.92 : 1.055 * ( Math.pow( c, 0.41666 ) ) - 0.055;

}