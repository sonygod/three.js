package three.js.src.renderers.shaders.ShaderChunk;

#if !defined(saturate)
// <common> may have defined saturate() already
#define saturate( a ) clamp( a, 0.0, 1.0 )
#end

uniform float toneMappingExposure;

// exposure only
function LinearToneMapping( color : Vec3 ) : Vec3 {

	return saturate( toneMappingExposure * color );

}

// source: https://www.cs.utah.edu/docs/techreports/2002/pdf/UUCS-02-001.pdf
function ReinhardToneMapping( color : Vec3 ) : Vec3 {

	color *= toneMappingExposure;
	return saturate( color / ( Vec3( 1.0 ) + color ) );

}

// source: http://filmicworlds.com/blog/filmic-tonemapping-operators/
function OptimizedCineonToneMapping( color : Vec3 ) : Vec3 {

	// optimized filmic operator by Jim Hejl and Richard Burgess-Dawson
	color *= toneMappingExposure;
	color = max( Vec3( 0.0 ), color - 0.004 );
	return pow( ( color * ( 6.2 * color + 0.5 ) ) / ( color * ( 6.2 * color + 1.7 ) + 0.06 ), Vec3( 2.2 ) );

}

// source: https://github.com/selfshadow/ltc_code/blob/master/webgl/shaders/ltc/ltc_blit.fs
function RRTAndODTFit( v : Vec3 ) : Vec3 {

	var a = v * ( v + 0.0245786 ) - 0.000090537;
	var b = v * ( 0.983729 * v + 0.4329510 ) + 0.238081;
	return a / b;

}

// this implementation of ACES is modified to accommodate a brighter viewing environment.
// the scale factor of 1/0.6 is subjective. see discussion in #19621.

function ACESFilmicToneMapping( color : Vec3 ) : Vec3 {

	// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
	const ACESInputMat : Mat3 = Mat3(
		Vec3( 0.59719, 0.07600, 0.02840 ), // transposed from source
		Vec3( 0.35458, 0.90834, 0.13383 ),
		Vec3( 0.04823, 0.01566, 0.83777 )
	);

	// ODT_SAT => XYZ => D60_2_D65 => sRGB
	const ACESOutputMat : Mat3 = Mat3(
		Vec3(  1.60475, -0.10208, -0.00327 ), // transposed from source
		Vec3( -0.53108,  1.10813, -0.07276 ),
		Vec3( -0.07367, -0.00605,  1.07602 )
	);

	color *= toneMappingExposure / 0.6;

	color = ACESInputMat * color;

	// Apply RRT and ODT
	color = RRTAndODTFit( color );

	color = ACESOutputMat * color;

	// Clamp to [0, 1]
	return saturate( color );

}

// Matrices for rec 2020 <> rec 709 color space conversion
// matrix provided in row-major order so it has been transposed
// https://www.itu.int/pub/R-REP-BT.2407-2017
const LINEAR_REC2020_TO_LINEAR_SRGB : Mat3 = Mat3(
	Vec3( 1.6605, - 0.1246, - 0.0182 ),
	Vec3( - 0.5876, 1.1329, - 0.1006 ),
	Vec3( - 0.0728, - 0.0083, 1.1187 )
);

const LINEAR_SRGB_TO_LINEAR_REC2020 : Mat3 = Mat3(
	Vec3( 0.6274, 0.0691, 0.0164 ),
	Vec3( 0.3293, 0.9195, 0.0880 ),
	Vec3( 0.0433, 0.0113, 0.8956 )
);

// https://iolite-engine.com/blog_posts/minimal_agx_implementation
// Mean error^2: 3.6705141e-06
function agxDefaultContrastApprox( x : Vec3 ) : Vec3 {

	var x2 = x * x;
	var x4 = x2 * x2;

	return + 15.5 * x4 * x2
		- 40.14 * x4 * x
		+ 31.96 * x4
		- 6.868 * x2 * x
		+ 0.4298 * x2
		+ 0.1191 * x
		- 0.00232;

}

// AgX Tone Mapping implementation based on Filament, which in turn is based
// on Blender's implementation using rec 2020 primaries
// https://github.com/google/filament/pull/7236
// Inputs and outputs are encoded as Linear-sRGB.

function AgXToneMapping( color : Vec3 ) : Vec3 {

	// AgX constants
	const AgXInsetMatrix : Mat3 = Mat3(
		Vec3( 0.856627153315983, 0.137318972929847, 0.11189821299995 ),
		Vec3( 0.0951212405381588, 0.761241990602591, 0.0767994186031903 ),
		Vec3( 0.0482516061458583, 0.101439036467562, 0.811302368396859 )
	);

	// explicit AgXOutsetMatrix generated from Filaments AgXOutsetMatrixInv
	const AgXOutsetMatrix : Mat3 = Mat3(
		Vec3( 1.1271005818144368, - 0.1413297634984383, - 0.14132976349843826 ),
		Vec3( - 0.11060664309660323, 1.157823702216272, - 0.11060664309660294 ),
		Vec3( - 0.016493938717834573, - 0.016493938717834257, 1.2519364065950405 )
	);

	// LOG2_MIN      = -10.0
	// LOG2_MAX      =  +6.5
	// MIDDLE_GRAY   =  0.18
	const AgxMinEv : Float = - 12.47393;  // log2( pow( 2, LOG2_MIN ) * MIDDLE_GRAY )
	const AgxMaxEv : Float = 4.026069;    // log2( pow( 2, LOG2_MAX ) * MIDDLE_GRAY )

	color *= toneMappingExposure;

	color = LINEAR_SRGB_TO_LINEAR_REC2020 * color;

	color = AgXInsetMatrix * color;

	// Log2 encoding
	color = max( color, 1e-10 ); // avoid 0 or negative numbers for log2
	color = log2( color );
	color = ( color - AgxMinEv ) / ( AgxMaxEv - AgxMinEv );

	color = clamp( color, 0.0, 1.0 );

	// Apply sigmoid
	color = agxDefaultContrastApprox( color );

	// Apply AgX look
	// v = agxLook(v, look);

	color = AgXOutsetMatrix * color;

	// Linearize
	color = pow( max( Vec3( 0.0 ), color ), Vec3( 2.2 ) );

	color = LINEAR_REC2020_TO_LINEAR_SRGB * color;

	// Gamut mapping. Simple clamp for now.
	color = clamp( color, 0.0, 1.0 );

	return color;

}

// https://modelviewer.dev/examples/tone-mapping

function NeutralToneMapping( color : Vec3 ) : Vec3 {

	const StartCompression : Float = 0.8 - 0.04;
	const Desaturation : Float = 0.15;

	color *= toneMappingExposure;

	var x = min( color.r, min( color.g, color.b ) );

	var offset = x < 0.08 ? x - 6.25 * x * x : 0.04;

	color -= offset;

	var peak = max( color.r, max( color.g, color.b ) );

	if ( peak < StartCompression ) return color;

	var d = 1. - StartCompression;

	var newPeak = 1. - d * d / ( peak + d - StartCompression );

	color *= newPeak / peak;

	var g = 1. - 1. / ( Desaturation * ( peak - newPeak ) + 1. );

	return mix( color, Vec3( newPeak ), g );

}

function CustomToneMapping( color : Vec3 ) : Vec3 { return color; }