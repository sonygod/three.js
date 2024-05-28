package three.shader;

#if js

@:native("ShaderChunk") extern class ShaderChunk {
  public static inline function fog_pars_fragment():String {
    return [
      #if USE_FOG
      "
      uniform vec3 fogColor;
      varying float vFogDepth;

      #if FOG_EXP2
      uniform float fogDensity;
      #else
      uniform float fogNear;
      uniform float fogFar;
      #end
      "
    ].join("");
  }
}

#else

#error "This code is only compatible with JavaScript target"

#end