package three.renderers.shaders;

class MapParsFragmentShader {
    public static var shader:String = '

#ifdef USE_MAP

    uniform sampler2D map;

#endif

';
}