import haxe.io.Bytes;
import haxe.io.File;
import haxe.io.Path;

class ShaderChunk {
  public static var alphahash_fragment:String = loadShader("ShaderChunk/alphahash_fragment.glsl.js");
  public static var alphahash_pars_fragment:String = loadShader("ShaderChunk/alphahash_pars_fragment.glsl.js");
  public static var alphamap_fragment:String = loadShader("ShaderChunk/alphamap_fragment.glsl.js");
  public static var alphamap_pars_fragment:String = loadShader("ShaderChunk/alphamap_pars_fragment.glsl.js");
  public static var alphatest_fragment:String = loadShader("ShaderChunk/alphatest_fragment.glsl.js");
  public static var alphatest_pars_fragment:String = loadShader("ShaderChunk/alphatest_pars_fragment.glsl.js");
  public static var aomap_fragment:String = loadShader("ShaderChunk/aomap_fragment.glsl.js");
  public static var aomap_pars_fragment:String = loadShader("ShaderChunk/aomap_pars_fragment.glsl.js");
  public static var batching_pars_vertex:String = loadShader("ShaderChunk/batching_pars_vertex.glsl.js");
  public static var batching_vertex:String = loadShader("ShaderChunk/batching_vertex.glsl.js");
  public static var begin_vertex:String = loadShader("ShaderChunk/begin_vertex.glsl.js");
  public static var beginnormal_vertex:String = loadShader("ShaderChunk/beginnormal_vertex.glsl.js");
  public static var bsdfs:String = loadShader("ShaderChunk/bsdfs.glsl.js");
  public static var iridescence_fragment:String = loadShader("ShaderChunk/iridescence_fragment.glsl.js");
  public static var bumpmap_pars_fragment:String = loadShader("ShaderChunk/bumpmap_pars_fragment.glsl.js");
  public static var clipping_planes_fragment:String = loadShader("ShaderChunk/clipping_planes_fragment.glsl.js");
  public static var clipping_planes_pars_fragment:String = loadShader("ShaderChunk/clipping_planes_pars_fragment.glsl.js");
  public static var clipping_planes_pars_vertex:String = loadShader("ShaderChunk/clipping_planes_pars_vertex.glsl.js");
  public static var clipping_planes_vertex:String = loadShader("ShaderChunk/clipping_planes_vertex.glsl.js");
  public static var color_fragment:String = loadShader("ShaderChunk/color_fragment.glsl.js");
  public static var color_pars_fragment:String = loadShader("ShaderChunk/color_pars_fragment.glsl.js");
  public static var color_pars_vertex:String = loadShader("ShaderChunk/color_pars_vertex.glsl.js");
  public static var color_vertex:String = loadShader("ShaderChunk/color_vertex.glsl.js");
  public static var common:String = loadShader("ShaderChunk/common.glsl.js");
  public static var cube_uv_reflection_fragment:String = loadShader("ShaderChunk/cube_uv_reflection_fragment.glsl.js");
  public static var defaultnormal_vertex:String = loadShader("ShaderChunk/defaultnormal_vertex.glsl.js");
  public static var displacementmap_pars_vertex:String = loadShader("ShaderChunk/displacementmap_pars_vertex.glsl.js");
  public static var displacementmap_vertex:String = loadShader("ShaderChunk/displacementmap_vertex.glsl.js");
  public static var emissivemap_fragment:String = loadShader("ShaderChunk/emissivemap_fragment.glsl.js");
  public static var emissivemap_pars_fragment:String = loadShader("ShaderChunk/emissivemap_pars_fragment.glsl.js");
  public static var colorspace_fragment:String = loadShader("ShaderChunk/colorspace_fragment.glsl.js");
  public static var colorspace_pars_fragment:String = loadShader("ShaderChunk/colorspace_pars_fragment.glsl.js");
  public static var envmap_fragment:String = loadShader("ShaderChunk/envmap_fragment.glsl.js");
  public static var envmap_common_pars_fragment:String = loadShader("ShaderChunk/envmap_common_pars_fragment.glsl.js");
  public static var envmap_pars_fragment:String = loadShader("ShaderChunk/envmap_pars_fragment.glsl.js");
  public static var envmap_pars_vertex:String = loadShader("ShaderChunk/envmap_pars_vertex.glsl.js");
  public static var envmap_vertex:String = loadShader("ShaderChunk/envmap_vertex.glsl.js");
  public static var fog_vertex:String = loadShader("ShaderChunk/fog_vertex.glsl.js");
  public static var fog_pars_vertex:String = loadShader("ShaderChunk/fog_pars_vertex.glsl.js");
  public static var fog_fragment:String = loadShader("ShaderChunk/fog_fragment.glsl.js");
  public static var fog_pars_fragment:String = loadShader("ShaderChunk/fog_pars_fragment.glsl.js");
  public static var gradientmap_pars_fragment:String = loadShader("ShaderChunk/gradientmap_pars_fragment.glsl.js");
  public static var lightmap_pars_fragment:String = loadShader("ShaderChunk/lightmap_pars_fragment.glsl.js");
  public static var lights_lambert_fragment:String = loadShader("ShaderChunk/lights_lambert_fragment.glsl.js");
  public static var lights_lambert_pars_fragment:String = loadShader("ShaderChunk/lights_lambert_pars_fragment.glsl.js");
  public static var lights_pars_begin:String = loadShader("ShaderChunk/lights_pars_begin.glsl.js");
  public static var envmap_physical_pars_fragment:String = loadShader("ShaderChunk/envmap_physical_pars_fragment.glsl.js");
  public static var lights_toon_fragment:String = loadShader("ShaderChunk/lights_toon_fragment.glsl.js");
  public static var lights_toon_pars_fragment:String = loadShader("ShaderChunk/lights_toon_pars_fragment.glsl.js");
  public static var lights_phong_fragment:String = loadShader("ShaderChunk/lights_phong_fragment.glsl.js");
  public static var lights_phong_pars_fragment:String = loadShader("ShaderChunk/lights_phong_pars_fragment.glsl.js");
  public static var lights_physical_fragment:String = loadShader("ShaderChunk/lights_physical_fragment.glsl.js");
  public static var lights_physical_pars_fragment:String = loadShader("ShaderChunk/lights_physical_pars_fragment.glsl.js");
  public static var lights_fragment_begin:String = loadShader("ShaderChunk/lights_fragment_begin.glsl.js");
  public static var lights_fragment_maps:String = loadShader("ShaderChunk/lights_fragment_maps.glsl.js");
  public static var lights_fragment_end:String = loadShader("ShaderChunk/lights_fragment_end.glsl.js");
  public static var logdepthbuf_fragment:String = loadShader("ShaderChunk/logdepthbuf_fragment.glsl.js");
  public static var logdepthbuf_pars_fragment:String = loadShader("ShaderChunk/logdepthbuf_pars_fragment.glsl.js");
  public static var logdepthbuf_pars_vertex:String = loadShader("ShaderChunk/logdepthbuf_pars_vertex.glsl.js");
  public static var logdepthbuf_vertex:String = loadShader("ShaderChunk/logdepthbuf_vertex.glsl.js");
  public static var map_fragment:String = loadShader("ShaderChunk/map_fragment.glsl.js");
  public static var map_pars_fragment:String = loadShader("ShaderChunk/map_pars_fragment.glsl.js");
  public static var map_particle_fragment:String = loadShader("ShaderChunk/map_particle_fragment.glsl.js");
  public static var map_particle_pars_fragment:String = loadShader("ShaderChunk/map_particle_pars_fragment.glsl.js");
  public static var metalnessmap_fragment:String = loadShader("ShaderChunk/metalnessmap_fragment.glsl.js");
  public static var metalnessmap_pars_fragment:String = loadShader("ShaderChunk/metalnessmap_pars_fragment.glsl.js");
  public static var morphinstance_vertex:String = loadShader("ShaderChunk/morphinstance_vertex.glsl.js");
  public static var morphcolor_vertex:String = loadShader("ShaderChunk/morphcolor_vertex.glsl.js");
  public static var morphnormal_vertex:String = loadShader("ShaderChunk/morphnormal_vertex.glsl.js");
  public static var morphtarget_pars_vertex:String = loadShader("ShaderChunk/morphtarget_pars_vertex.glsl.js");
  public static var morphtarget_vertex:String = loadShader("ShaderChunk/morphtarget_vertex.glsl.js");
  public static var normal_fragment_begin:String = loadShader("ShaderChunk/normal_fragment_begin.glsl.js");
  public static var normal_fragment_maps:String = loadShader("ShaderChunk/normal_fragment_maps.glsl.js");
  public static var normal_pars_fragment:String = loadShader("ShaderChunk/normal_pars_fragment.glsl.js");
  public static var normal_pars_vertex:String = loadShader("ShaderChunk/normal_pars_vertex.glsl.js");
  public static var normal_vertex:String = loadShader("ShaderChunk/normal_vertex.glsl.js");
  public static var normalmap_pars_fragment:String = loadShader("ShaderChunk/normalmap_pars_fragment.glsl.js");
  public static var clearcoat_normal_fragment_begin:String = loadShader("ShaderChunk/clearcoat_normal_fragment_begin.glsl.js");
  public static var clearcoat_normal_fragment_maps:String = loadShader("ShaderChunk/clearcoat_normal_fragment_maps.glsl.js");
  public static var clearcoat_pars_fragment:String = loadShader("ShaderChunk/clearcoat_pars_fragment.glsl.js");
  public static var iridescence_pars_fragment:String = loadShader("ShaderChunk/iridescence_pars_fragment.glsl.js");
  public static var opaque_fragment:String = loadShader("ShaderChunk/opaque_fragment.glsl.js");
  public static var packing:String = loadShader("ShaderChunk/packing.glsl.js");
  public static var premultiplied_alpha_fragment:String = loadShader("ShaderChunk/premultiplied_alpha_fragment.glsl.js");
  public static var project_vertex:String = loadShader("ShaderChunk/project_vertex.glsl.js");
  public static var dithering_fragment:String = loadShader("ShaderChunk/dithering_fragment.glsl.js");
  public static var dithering_pars_fragment:String = loadShader("ShaderChunk/dithering_pars_fragment.glsl.js");
  public static var roughnessmap_fragment:String = loadShader("ShaderChunk/roughnessmap_fragment.glsl.js");
  public static var roughnessmap_pars_fragment:String = loadShader("ShaderChunk/roughnessmap_pars_fragment.glsl.js");
  public static var shadowmap_pars_fragment:String = loadShader("ShaderChunk/shadowmap_pars_fragment.glsl.js");
  public static var shadowmap_pars_vertex:String = loadShader("ShaderChunk/shadowmap_pars_vertex.glsl.js");
  public static var shadowmap_vertex:String = loadShader("ShaderChunk/shadowmap_vertex.glsl.js");
  public static var shadowmask_pars_fragment:String = loadShader("ShaderChunk/shadowmask_pars_fragment.glsl.js");
  public static var skinbase_vertex:String = loadShader("ShaderChunk/skinbase_vertex.glsl.js");
  public static var skinning_pars_vertex:String = loadShader("ShaderChunk/skinning_pars_vertex.glsl.js");
  public static var skinning_vertex:String = loadShader("ShaderChunk/skinning_vertex.glsl.js");
  public static var skinnormal_vertex:String = loadShader("ShaderChunk/skinnormal_vertex.glsl.js");
  public static var specularmap_fragment:String = loadShader("ShaderChunk/specularmap_fragment.glsl.js");
  public static var specularmap_pars_fragment:String = loadShader("ShaderChunk/specularmap_pars_fragment.glsl.js");
  public static var tonemapping_fragment:String = loadShader("ShaderChunk/tonemapping_fragment.glsl.js");
  public static var tonemapping_pars_fragment:String = loadShader("ShaderChunk/tonemapping_pars_fragment.glsl.js");
  public static var transmission_fragment:String = loadShader("ShaderChunk/transmission_fragment.glsl.js");
  public static var transmission_pars_fragment:String = loadShader("ShaderChunk/transmission_pars_fragment.glsl.js");
  public static var uv_pars_fragment:String = loadShader("ShaderChunk/uv_pars_fragment.glsl.js");
  public static var uv_pars_vertex:String = loadShader("ShaderChunk/uv_pars_vertex.glsl.js");
  public static var uv_vertex:String = loadShader("ShaderChunk/uv_vertex.glsl.js");
  public static var worldpos_vertex:String = loadShader("ShaderChunk/worldpos_vertex.glsl.js");

  public static var background_vert:String = loadShader("ShaderLib/background.glsl.js");
  public static var background_frag:String = loadShader("ShaderLib/background.glsl.js");
  public static var backgroundCube_vert:String = loadShader("ShaderLib/backgroundCube.glsl.js");
  public static var backgroundCube_frag:String = loadShader("ShaderLib/backgroundCube.glsl.js");
  public static var cube_vert:String = loadShader("ShaderLib/cube.glsl.js");
  public static var cube_frag:String = loadShader("ShaderLib/cube.glsl.js");
  public static var depth_vert:String = loadShader("ShaderLib/depth.glsl.js");
  public static var depth_frag:String = loadShader("ShaderLib/depth.glsl.js");
  public static var distanceRGBA_vert:String = loadShader("ShaderLib/distanceRGBA.glsl.js");
  public static var distanceRGBA_frag:String = loadShader("ShaderLib/distanceRGBA.glsl.js");
  public static var equirect_vert:String = loadShader("ShaderLib/equirect.glsl.js");
  public static var equirect_frag:String = loadShader("ShaderLib/equirect.glsl.js");
  public static var linedashed_vert:String = loadShader("ShaderLib/linedashed.glsl.js");
  public static var linedashed_frag:String = loadShader("ShaderLib/linedashed.glsl.js");
  public static var meshbasic_vert:String = loadShader("ShaderLib/meshbasic.glsl.js");
  public static var meshbasic_frag:String = loadShader("ShaderLib/meshbasic.glsl.js");
  public static var meshlambert_vert:String = loadShader("ShaderLib/meshlambert.glsl.js");
  public static var meshlambert_frag:String = loadShader("ShaderLib/meshlambert.glsl.js");
  public static var meshmatcap_vert:String = loadShader("ShaderLib/meshmatcap.glsl.js");
  public static var meshmatcap_frag:String = loadShader("ShaderLib/meshmatcap.glsl.js");
  public static var meshnormal_vert:String = loadShader("ShaderLib/meshnormal.glsl.js");
  public static var meshnormal_frag:String = loadShader("ShaderLib/meshnormal.glsl.js");
  public static var meshphong_vert:String = loadShader("ShaderLib/meshphong.glsl.js");
  public static var meshphong_frag:String = loadShader("ShaderLib/meshphong.glsl.js");
  public static var meshphysical_vert:String = loadShader("ShaderLib/meshphysical.glsl.js");
  public static var meshphysical_frag:String = loadShader("ShaderLib/meshphysical.glsl.js");
  public static var meshtoon_vert:String = loadShader("ShaderLib/meshtoon.glsl.js");
  public static var meshtoon_frag:String = loadShader("ShaderLib/meshtoon.glsl.js");
  public static var points_vert:String = loadShader("ShaderLib/points.glsl.js");
  public static var points_frag:String = loadShader("ShaderLib/points.glsl.js");
  public static var shadow_vert:String = loadShader("ShaderLib/shadow.glsl.js");
  public static var shadow_frag:String = loadShader("ShaderLib/shadow.glsl.js");
  public static var sprite_vert:String = loadShader("ShaderLib/sprite.glsl.js");
  public static var sprite_frag:String = loadShader("ShaderLib/sprite.glsl.js");

  static function loadShader(path:String):String {
    var fullPath = Path.join(["src", path]);
    var bytes = File.getBytes(fullPath);
    return String.fromCharCode(bytes.b);
  }
}


**Explanation:**

1. **Import necessary Haxe libraries:**
   - `haxe.io.Bytes`: For reading file contents as bytes.
   - `haxe.io.File`: For reading files.
   - `haxe.io.Path`: For combining path components.

2. **Create a `ShaderChunk` class:**
   - This class acts as a container for all your shader chunks.
   - Each shader chunk is declared as a `public static var` with the corresponding name.

3. **Load shader chunks from files:**
   - The `loadShader` function takes a path relative to the `src` directory and returns the shader code as a string.
   - The `File.getBytes` function reads the file content as bytes.
   - `String.fromCharCode` converts the bytes array to a string.

4. **Initialize each shader chunk:**
   - Each `public static var` is initialized by calling the `loadShader` function with the appropriate path.

**To use this in your Haxe project:**

1. **Place the `.glsl.js` files in the `src` directory.**
2. **Import the `ShaderChunk` class in your code.**
3. **Access the shader chunks by their names:**
   
   var vertexShader:String = ShaderChunk.meshbasic_vert;
   var fragmentShader:String = ShaderChunk.meshbasic_frag;