package three.js.src.renderers.shaders.ShaderChunk;

#if (js && (USE_ENVMAP))

@:uniform var reflectivity:Float;

#if (USE_BUMPMAP || USE_NORMALMAP || PHONG || LAMBERT)

#define ENV_WORLDPOS

#end

#if ENV_WORLDPOS

@:varying var vWorldPosition: Vec3;
@:uniform var refractionRatio:Float;

#else

@:varying var vReflect: Vec3;

#end

#end