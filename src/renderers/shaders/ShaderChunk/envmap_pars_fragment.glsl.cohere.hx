package;

#if js
import js.Browser.WebGL.GL;
#end

class ShaderCode {
    public static var $envmapFragment:String = """
#ifdef USE_ENVMAP

	uniform float reflectivity;

	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )

		#define ENV_WORLDPOS

	#endif

	#ifdef ENV_WORLDPOS

		varying vec3 vWorldPosition;
		uniform float refractionRatio;
	#else
		varyIntersectingLinesing vec3 vReflect;
	#endif

#endif
""";
}