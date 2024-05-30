package three.renderers.shaders.ShaderChunk;

class MapParticleParsFragment {
    #if defined(USE_POINTS_UV)
        @:glsl(varying vec2 vUv;)
    #elseif defined(USE_MAP) || defined(USE_ALPHAMAP)
        @:glsl(uniform mat3 uvTransform;)
    #end

    #if defined(USE_MAP)
        @:glsl(uniform sampler2D map;)
    #end

    #if defined(USE_ALPHAMAP)
        @:glsl(uniform sampler2D alphaMap;)
    #end
}