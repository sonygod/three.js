package three.js.src.renderers.shaders.ShaderChunk;

import haxe.macro.Expr;

class EnvmapParsVertexGlsl {
  public static var GLSL(default, null) = '
#ifdef USE_ENVMAP

  #if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )

    #define ENV_WORLDPOS

  #endif

  #ifdef ENV_WORLDPOS

    varying vec3 vWorldPosition;

  #else

    varying vec3 vReflect;
    uniform float refractionRatio;

  #endif

#endif
';
}