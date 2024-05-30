package three.renderers.shaders.ShaderChunk;

@:build(macro.ShaderMacro.vertex)
class ProjectVertex {
  static function vertex(mvPosition: Vec4, transformed: Vec3, modelViewMatrix: Mat4, projectionMatrix: Mat4, ?batchingMatrix: Mat4, ?instanceMatrix: Mat4) {
    mvPosition = Vec4(transformed, 1.0);

    #if (USE_BATCHING)
      mvPosition = batchingMatrix * mvPosition;
    #end

    #if (USE_INSTANCING)
      mvPosition = instanceMatrix * mvPosition;
    #end

    mvPosition = modelViewMatrix * mvPosition;

    gl_Position = projectionMatrix * mvPosition;

    return mvPosition;
  }
}