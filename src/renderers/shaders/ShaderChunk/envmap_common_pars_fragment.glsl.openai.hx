package three.renderers.shaders;

class ShaderChunk {
    @:glsl("
#ifdef USE_ENVMAP

uniform float envMapIntensity;
uniform float flipEnvMap;
uniform mat3 envMapRotation;

#ifdef ENVMAP_TYPE_CUBE
uniform samplerCube envMap;
#else
uniform sampler2D envMap;
#endif

#endif
")
    public static var envmap_common_pars_fragment = "";
}