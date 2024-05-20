@:build(three.js.src.renderers.shaders.ShaderChunk.envmap_vertex.glsl.js)
class EnvmapVertexShader {
    static var code:String = #if USE_ENVMAP
        #if ENV_WORLDPOS
            vWorldPosition = worldPosition.xyz;
        #else
            vec3 cameraToVertex;
            #if isOrthographic
                cameraToVertex = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
            #else
                cameraToVertex = normalize( worldPosition.xyz - cameraPosition );
            #end
            vec3 worldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
            #if ENVMAP_MODE_REFLECTION
                vReflect = reflect( cameraToVertex, worldNormal );
            #else
                vReflect = refract( cameraToVertex, worldNormal, refractionRatio );
            #end
        #end
    #end;
}