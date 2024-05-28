package three.shader;

class ClippingPlanesVertex {
    public static var shader:String = [
#if NUM_CLIPPING_PLANES > 0
        "vClipPosition = -mvPosition.xyz;"
#
    ].join("\n");
}