// File path: three.js/src/renderers/shaders/ShaderChunk/envmap_common_pars_fragment.glsl.hx

#if USE_ENVMAP

uniform var envMapIntensity:Float;
uniform var flipEnvMap:Float;
uniform var envMapRotation:Mat3;

#if ENVMAP_TYPE_CUBE
uniform var envMap:SamplerCube;
#else
uniform var envMap:Sampler2D;
#endif

#end