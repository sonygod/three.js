package three.shader;

#if (js && three)

class FogParsVertex {
    #if USE_FOG
    public var vFogDepth:Float;
    #end
}

#end