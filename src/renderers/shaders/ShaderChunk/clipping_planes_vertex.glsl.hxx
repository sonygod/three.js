class ClippingPlanesVertexShader {
    static var glsl:String = #if NUM_CLIPPING_PLANES > 0

        vClipPosition = - mvPosition.xyz;

    #end;
}