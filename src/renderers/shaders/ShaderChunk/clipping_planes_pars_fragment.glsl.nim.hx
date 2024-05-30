package three.renderers.shaders.ShaderChunk;

class clipping_planes_pars_fragment {
    #if (NUM_CLIPPING_PLANES > 0)
    static var vClipPosition:Float32Array;

    static var clippingPlanes:Array<Float32Array>;
    #end

    static function main() {
        #if (NUM_CLIPPING_PLANES > 0)
        vClipPosition = new Float32Array(3);

        clippingPlanes = new Array<Float32Array>();
        for (i in 0...NUM_CLIPPING_PLANES) {
            clippingPlanes[i] = new Float32Array(4);
        }
        #end
    }
}