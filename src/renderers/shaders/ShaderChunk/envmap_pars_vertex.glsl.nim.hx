package three.src.renderers.shaders.ShaderChunk;

@:build(macro.Library.export())
class envmap_pars_vertex {
  static var code = new StringBuf();

  static macro function build() {
    #if use_envmap
      #if use_bumpmap || use_normalmap || phong || lambert
        #define env_worldpos
      #end

      #if env_worldpos
        code.add("varying vec3 vWorldPosition;\n");
      #else
        code.add("varying vec3 vReflect;\n");
        code.add("uniform float refractionRatio;\n");
      #end
    #end

    return code;
  }
}