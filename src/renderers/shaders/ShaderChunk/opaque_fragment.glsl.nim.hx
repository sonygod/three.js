package three.src.renderers.shaders.ShaderChunk;

class OpaqueFragment {
  public static inline function main() {
    #if (opaque)
      diffuseColor.a = 1.0;
    #end

    #if (use_transmission)
      diffuseColor.a *= material.transmissionAlpha;
    #end

    gl_FragColor = Vec4(outgoingLight, diffuseColor.a);
  }
}