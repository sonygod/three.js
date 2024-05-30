package three.shader;

class DisplacementMapVertexShader {
  static public inline function shader() {
    #if USE_DISPLACEMENTMAP
    transformed += normalize(objectNormal) * (texture2D(displacementMap, vDisplacementMapUv).x * displacementScale + displacementBias);
    #end
  }
}