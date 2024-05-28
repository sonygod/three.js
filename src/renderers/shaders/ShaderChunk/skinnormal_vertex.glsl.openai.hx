package three.js.src.renderers.shaders.ShaderChunk;

class SkinnormalVertex {
  @glslCode("// Vertex shader code")
  static inline function vertexShader():Void {
    #if USE_SKINNING
    var skinMatrix:Mat4 = new Mat4(0.0);
    skinMatrix += skinWeight.x * boneMatX;
    skinMatrix += skinWeight.y * boneMatY;
    skinMatrix += skinWeight.z * boneMatZ;
    skinMatrix += skinWeight.w * boneMatW;
    skinMatrix = bindMatrixInverse * skinMatrix * bindMatrix;

    objectNormal = new Vec3(skinMatrix * new Vec4(objectNormal, 0.0));

    #if USE_TANGENT
    objectTangent = new Vec3(skinMatrix * new Vec4(objectTangent, 0.0));
    #end
    #end
  }
}