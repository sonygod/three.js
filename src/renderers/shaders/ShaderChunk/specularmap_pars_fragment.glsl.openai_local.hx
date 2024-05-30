package three.renderers.shaders.ShaderChunk;

class SpecularMapParsFragment {
    public static var shaderCode:String = '
        #ifdef USE_SPECULARMAP

        uniform sampler2D specularMap;

        #endif
    ';
}