#if openfl_gl

uniform float envMapIntensity;
uniform float flipEnvMap;
uniform mat3 envMapRotation;

#if openfl_gl_texture_cube
uniform samplerCube envMap;
#else
uniform sampler2D envMap;
#end

#end