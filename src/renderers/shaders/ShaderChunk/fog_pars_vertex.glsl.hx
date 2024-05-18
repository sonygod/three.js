package three.shader;

class FogParsVertex {
    #if (USE_FOG)
    @:glsl("varying float vFogDepth;");
    #end
}