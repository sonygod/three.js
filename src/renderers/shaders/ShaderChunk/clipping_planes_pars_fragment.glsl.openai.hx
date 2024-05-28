@:glsl(" fragment ")
class ClippingPlanesPars {
    #if NUM_CLIPPING_PLANES > 0

    @:varying var vClipPosition:Vec3;

    @:uniform var clippingPlanes:Array<Vec4>;

    #end
}