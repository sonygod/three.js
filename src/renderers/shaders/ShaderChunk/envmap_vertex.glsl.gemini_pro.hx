import haxe.macro.Expr;

class Glsl {
  static macro function glsl(code:Expr):Expr {
    return macro {
      #if (js)
        `export default /* glsl */\`${code}\``
      #else
        ${code}
      #endif
    };
  }
}

class EnvMap {
  static macro function envMap(code:Expr):Expr {
    return macro {
      #if (js)
        ${Glsl.glsl(code)}
      #else
        ${code}
      #endif
    };
  }
}

class Main {
  static macro function main():Expr {
    return macro {
      ${EnvMap.envMap(
        `
#ifdef USE_ENVMAP

	#ifdef ENV_WORLDPOS

		vWorldPosition = worldPosition.xyz;

	#else

		vec3 cameraToVertex;

		if ( isOrthographic ) {

			cameraToVertex = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );

		} else {

			cameraToVertex = normalize( worldPosition.xyz - cameraPosition );

		}

		vec3 worldNormal = inverseTransformDirection( transformedNormal, viewMatrix );

		#ifdef ENVMAP_MODE_REFLECTION

			vReflect = reflect( cameraToVertex, worldNormal );

		#else

			vReflect = refract( cameraToVertex, worldNormal, refractionRatio );

		#endif

	#endif

#endif
`
      )}
    };
  }
}