package three.shader;

@:glsl("fragment")
class LightmapParsFragment {

    #ifdef USE_LIGHTMAP

    @:uniform public var lightMap:Sampler2D;
    @:uniform public var lightMapIntensity:Float;

    #end

}