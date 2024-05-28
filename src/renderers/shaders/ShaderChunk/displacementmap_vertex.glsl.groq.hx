@:glsl
class DisplacementMapVertexShader {
    public function new() {}

    public function vertex() {
        #ifdef USE_DISPLACEMENTMAP
        transformed += normalize(objectNormal) * (texture2D(displacementMap, vDisplacementMapUv).x * displacementScale + displacementBias);
        #endif
    }
}