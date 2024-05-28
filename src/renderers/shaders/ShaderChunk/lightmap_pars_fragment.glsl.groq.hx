package three.shader;

import haxe.Resource;

@:resource("three/shaders/lightmap_pars_fragment.glsl")
class LightmapParsFragmentShader {
    #ifdef USE_LIGHTMAP

    @:uniform public var lightMap:Resource_sampler2D;
    @:uniform public var lightMapIntensity:Float;

    #end
}