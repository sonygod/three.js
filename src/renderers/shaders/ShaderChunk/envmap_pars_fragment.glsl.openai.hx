package three.renderers.shaders.ShaderChunk;

#if USE_ENVMAP

@:uniform var reflectivity:Float = 0.0;

#if (USE_BUMPMAP || USE_NORMALMAP || PHONG || LAMBERT)

	#define ENV_WORLDPOS

#end

#if ENV_WORLDPOS

	var vWorldPosition:Vec3;

	@:uniform var refractionRatio:Float = 0.0;

#else

	var vReflect:Vec3;

#end

#end