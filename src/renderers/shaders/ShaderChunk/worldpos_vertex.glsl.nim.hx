package three.src.renderers.shaders.ShaderChunk;

class WorldposVertex {
    static public var code:String =
#if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0

	"	vec4 worldPosition = vec4( transformed, 1.0 );" +

	#if defined( USE_BATCHING )

		"	worldPosition = batchingMatrix * worldPosition;" +

	#end

	#if defined( USE_INSTANCING )

		"	worldPosition = instanceMatrix * worldPosition;" +

	#end

	"	worldPosition = modelMatrix * worldPosition;" +

#end
	"";
}