package three.renderers.shaders.ShaderChunk;

#if (js && !display)

@:-glsl("fog_pars_fragment")
class FogParsFragment {
    #if USE_FOG

    @:uniform public var fogColor:Vec3;
    @:varying public var vFogDepth:Float;

    #if FOG_EXP2

    @:uniform public var fogDensity:Float;

    #else

    @:uniform public var fogNear:Float;
    @:uniform public var fogFar:Float;

    #end

    #end
}

#else

#error "Only JavaScript target is supported"

#end