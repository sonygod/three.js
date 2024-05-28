@:glsl("
#if defined( USE_POINTS_UV )

	var vUv : Vec2;

#else

	#if defined( USE_MAP ) || defined( USE_ALPHAMAP )

	var uvTransform : Mat3;

	#endif

#endif

#ifdef USE_MAP

	var map : Sampler2D;

#endif

#ifdef USE_ALPHAMAP

	var alphaMap : Sampler2D;

#endif
")
class ShaderChunk {}