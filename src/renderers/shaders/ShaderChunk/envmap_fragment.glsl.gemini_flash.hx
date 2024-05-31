class Main {
  public static function main():Void {
    var glsl = /* glsl */"
#ifdef USE_ENVMAP

	#ifdef ENV_WORLDPOS

		vec3 cameraToFrag;

		if ( isOrthographic ) {

			cameraToFrag = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );

		} else {

			cameraToFrag = normalize( vWorldPosition - cameraPosition );

		}

		// Transforming Normal Vectors with the Inverse Transformation
		vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );

		#ifdef ENVMAP_MODE_REFLECTION

			vec3 reflectVec = reflect( cameraToFrag, worldNormal );

		#else

			vec3 reflectVec = refract( cameraToFrag, worldNormal, refractionRatio );

		#endif

	#else

		vec3 reflectVec = vReflect;

	#endif

	#ifdef ENVMAP_TYPE_CUBE

		vec4 envColor = textureCube( envMap, envMapRotation * vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );

	#else

		vec4 envColor = vec4( 0.0 );

	#endif

	#ifdef ENVMAP_BLENDING_MULTIPLY

		outgoingLight = mix( outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity );

	#elif defined( ENVMAP_BLENDING_MIX )

		outgoingLight = mix( outgoingLight, envColor.xyz, specularStrength * reflectivity );

	#elif defined( ENVMAP_BLENDING_ADD )

		outgoingLight += envColor.xyz * specularStrength * reflectivity;

	#endif

#endif
";
  }
}


The provided JavaScript code is already valid GLSL code wrapped in a JavaScript template literal. Haxe can directly use this code as a string without any modification.

**Explanation:**

1. **Haxe and GLSL:** Haxe doesn't directly "convert" to GLSL. GLSL (OpenGL Shading Language) is used for writing shaders, which run directly on the GPU. Haxe can be used to embed and manage GLSL code within your application.
2. **Template Literals:** The provided code uses JavaScript's template literals (backticks ``), which allow for multi-line strings and embedding expressions. Haxe also supports template literals with the same syntax.

**Therefore, you can use the provided JavaScript code directly within your Haxe project as a string containing your GLSL code.**

**Example (using Luxe engine):**


class MyShader extends luxe.shaders.Shader {
  public function new() {
    super({
      fragment: /* glsl */`
        // ... (Your GLSL code here)
      `
    });
  }
}