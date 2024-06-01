import haxe.io.File;
import haxe.io.Bytes;

class ShaderChunk {
  public static var alphahash_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/alphahash_fragment.glsl.js")));
  public static var alphahash_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/alphahash_pars_fragment.glsl.js")));
  public static var alphamap_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/alphamap_fragment.glsl.js")));
  public static var alphamap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/alphamap_pars_fragment.glsl.js")));
  public static var alphatest_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/alphatest_fragment.glsl.js")));
  public static var alphatest_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/alphatest_pars_fragment.glsl.js")));
  public static var aomap_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/aomap_fragment.glsl.js")));
  public static var aomap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/aomap_pars_fragment.glsl.js")));
  public static var batching_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/batching_pars_vertex.glsl.js")));
  public static var batching_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/batching_vertex.glsl.js")));
  public static var begin_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/begin_vertex.glsl.js")));
  public static var beginnormal_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/beginnormal_vertex.glsl.js")));
  public static var bsdfs:String = File.getContent(File.getContent(File.getContent("ShaderChunk/bsdfs.glsl.js")));
  public static var iridescence_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/iridescence_fragment.glsl.js")));
  public static var bumpmap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/bumpmap_pars_fragment.glsl.js")));
  public static var clipping_planes_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/clipping_planes_fragment.glsl.js")));
  public static var clipping_planes_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/clipping_planes_pars_fragment.glsl.js")));
  public static var clipping_planes_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/clipping_planes_pars_vertex.glsl.js")));
  public static var clipping_planes_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/clipping_planes_vertex.glsl.js")));
  public static var color_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/color_fragment.glsl.js")));
  public static var color_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/color_pars_fragment.glsl.js")));
  public static var color_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/color_pars_vertex.glsl.js")));
  public static var color_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/color_vertex.glsl.js")));
  public static var common:String = File.getContent(File.getContent(File.getContent("ShaderChunk/common.glsl.js")));
  public static var cube_uv_reflection_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/cube_uv_reflection_fragment.glsl.js")));
  public static var defaultnormal_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/defaultnormal_vertex.glsl.js")));
  public static var displacementmap_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/displacementmap_pars_vertex.glsl.js")));
  public static var displacementmap_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/displacementmap_vertex.glsl.js")));
  public static var emissivemap_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/emissivemap_fragment.glsl.js")));
  public static var emissivemap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/emissivemap_pars_fragment.glsl.js")));
  public static var colorspace_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/colorspace_fragment.glsl.js")));
  public static var colorspace_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/colorspace_pars_fragment.glsl.js")));
  public static var envmap_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/envmap_fragment.glsl.js")));
  public static var envmap_common_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/envmap_common_pars_fragment.glsl.js")));
  public static var envmap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/envmap_pars_fragment.glsl.js")));
  public static var envmap_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/envmap_pars_vertex.glsl.js")));
  public static var envmap_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/envmap_vertex.glsl.js")));
  public static var fog_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/fog_vertex.glsl.js")));
  public static var fog_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/fog_pars_vertex.glsl.js")));
  public static var fog_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/fog_fragment.glsl.js")));
  public static var fog_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/fog_pars_fragment.glsl.js")));
  public static var gradientmap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/gradientmap_pars_fragment.glsl.js")));
  public static var lightmap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lightmap_pars_fragment.glsl.js")));
  public static var lights_lambert_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_lambert_fragment.glsl.js")));
  public static var lights_lambert_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_lambert_pars_fragment.glsl.js")));
  public static var lights_pars_begin:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_pars_begin.glsl.js")));
  public static var envmap_physical_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/envmap_physical_pars_fragment.glsl.js")));
  public static var lights_toon_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_toon_fragment.glsl.js")));
  public static var lights_toon_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_toon_pars_fragment.glsl.js")));
  public static var lights_phong_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_phong_fragment.glsl.js")));
  public static var lights_phong_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_phong_pars_fragment.glsl.js")));
  public static var lights_physical_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_physical_fragment.glsl.js")));
  public static var lights_physical_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_physical_pars_fragment.glsl.js")));
  public static var lights_fragment_begin:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_fragment_begin.glsl.js")));
  public static var lights_fragment_maps:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_fragment_maps.glsl.js")));
  public static var lights_fragment_end:String = File.getContent(File.getContent(File.getContent("ShaderChunk/lights_fragment_end.glsl.js")));
  public static var logdepthbuf_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/logdepthbuf_fragment.glsl.js")));
  public static var logdepthbuf_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/logdepthbuf_pars_fragment.glsl.js")));
  public static var logdepthbuf_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/logdepthbuf_pars_vertex.glsl.js")));
  public static var logdepthbuf_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/logdepthbuf_vertex.glsl.js")));
  public static var map_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/map_fragment.glsl.js")));
  public static var map_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/map_pars_fragment.glsl.js")));
  public static var map_particle_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/map_particle_fragment.glsl.js")));
  public static var map_particle_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/map_particle_pars_fragment.glsl.js")));
  public static var metalnessmap_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/metalnessmap_fragment.glsl.js")));
  public static var metalnessmap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/metalnessmap_pars_fragment.glsl.js")));
  public static var morphinstance_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/morphinstance_vertex.glsl.js")));
  public static var morphcolor_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/morphcolor_vertex.glsl.js")));
  public static var morphnormal_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/morphnormal_vertex.glsl.js")));
  public static var morphtarget_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/morphtarget_pars_vertex.glsl.js")));
  public static var morphtarget_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/morphtarget_vertex.glsl.js")));
  public static var normal_fragment_begin:String = File.getContent(File.getContent(File.getContent("ShaderChunk/normal_fragment_begin.glsl.js")));
  public static var normal_fragment_maps:String = File.getContent(File.getContent(File.getContent("ShaderChunk/normal_fragment_maps.glsl.js")));
  public static var normal_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/normal_pars_fragment.glsl.js")));
  public static var normal_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/normal_pars_vertex.glsl.js")));
  public static var normal_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/normal_vertex.glsl.js")));
  public static var normalmap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/normalmap_pars_fragment.glsl.js")));
  public static var clearcoat_normal_fragment_begin:String = File.getContent(File.getContent(File.getContent("ShaderChunk/clearcoat_normal_fragment_begin.glsl.js")));
  public static var clearcoat_normal_fragment_maps:String = File.getContent(File.getContent(File.getContent("ShaderChunk/clearcoat_normal_fragment_maps.glsl.js")));
  public static var clearcoat_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/clearcoat_pars_fragment.glsl.js")));
  public static var iridescence_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/iridescence_pars_fragment.glsl.js")));
  public static var opaque_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/opaque_fragment.glsl.js")));
  public static var packing:String = File.getContent(File.getContent(File.getContent("ShaderChunk/packing.glsl.js")));
  public static var premultiplied_alpha_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/premultiplied_alpha_fragment.glsl.js")));
  public static var project_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/project_vertex.glsl.js")));
  public static var dithering_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/dithering_fragment.glsl.js")));
  public static var dithering_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/dithering_pars_fragment.glsl.js")));
  public static var roughnessmap_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/roughnessmap_fragment.glsl.js")));
  public static var roughnessmap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/roughnessmap_pars_fragment.glsl.js")));
  public static var shadowmap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/shadowmap_pars_fragment.glsl.js")));
  public static var shadowmap_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/shadowmap_pars_vertex.glsl.js")));
  public static var shadowmap_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/shadowmap_vertex.glsl.js")));
  public static var shadowmask_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/shadowmask_pars_fragment.glsl.js")));
  public static var skinbase_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/skinbase_vertex.glsl.js")));
  public static var skinning_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/skinning_pars_vertex.glsl.js")));
  public static var skinning_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/skinning_vertex.glsl.js")));
  public static var skinnormal_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/skinnormal_vertex.glsl.js")));
  public static var specularmap_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/specularmap_fragment.glsl.js")));
  public static var specularmap_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/specularmap_pars_fragment.glsl.js")));
  public static var tonemapping_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/tonemapping_fragment.glsl.js")));
  public static var tonemapping_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/tonemapping_pars_fragment.glsl.js")));
  public static var transmission_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/transmission_fragment.glsl.js")));
  public static var transmission_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/transmission_pars_fragment.glsl.js")));
  public static var uv_pars_fragment:String = File.getContent(File.getContent(File.getContent("ShaderChunk/uv_pars_fragment.glsl.js")));
  public static var uv_pars_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/uv_pars_vertex.glsl.js")));
  public static var uv_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/uv_vertex.glsl.js")));
  public static var worldpos_vertex:String = File.getContent(File.getContent(File.getContent("ShaderChunk/worldpos_vertex.glsl.js")));

  public static var background_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/background.glsl.js")));
  public static var background_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/background.glsl.js")));
  public static var backgroundCube_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/backgroundCube.glsl.js")));
  public static var backgroundCube_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/backgroundCube.glsl.js")));
  public static var cube_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/cube.glsl.js")));
  public static var cube_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/cube.glsl.js")));
  public static var depth_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/depth.glsl.js")));
  public static var depth_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/depth.glsl.js")));
  public static var distanceRGBA_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/distanceRGBA.glsl.js")));
  public static var distanceRGBA_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/distanceRGBA.glsl.js")));
  public static var equirect_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/equirect.glsl.js")));
  public static var equirect_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/equirect.glsl.js")));
  public static var linedashed_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/linedashed.glsl.js")));
  public static var linedashed_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/linedashed.glsl.js")));
  public static var meshbasic_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshbasic.glsl.js")));
  public static var meshbasic_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshbasic.glsl.js")));
  public static var meshlambert_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshlambert.glsl.js")));
  public static var meshlambert_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshlambert.glsl.js")));
  public static var meshmatcap_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshmatcap.glsl.js")));
  public static var meshmatcap_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshmatcap.glsl.js")));
  public static var meshnormal_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshnormal.glsl.js")));
  public static var meshnormal_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshnormal.glsl.js")));
  public static var meshphong_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshphong.glsl.js")));
  public static var meshphong_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshphong.glsl.js")));
  public static var meshphysical_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshphysical.glsl.js")));
  public static var meshphysical_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshphysical.glsl.js")));
  public static var meshtoon_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshtoon.glsl.js")));
  public static var meshtoon_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/meshtoon.glsl.js")));
  public static var points_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/points.glsl.js")));
  public static var points_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/points.glsl.js")));
  public static var shadow_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/shadow.glsl.js")));
  public static var shadow_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/shadow.glsl.js")));
  public static var sprite_vert:String = File.getContent(File.getContent(File.getContent("ShaderLib/sprite.glsl.js")));
  public static var sprite_frag:String = File.getContent(File.getContent(File.getContent("ShaderLib/sprite.glsl.js")));
}


**Explanation:**

1. **Imports:** We import the `File` and `Bytes` classes from `haxe.io` to handle file reading.
2. **Class Declaration:** The `ShaderChunk` class is declared.
3. **Static Variables:**  Each chunk is defined as a static variable of type `String` in the `ShaderChunk` class. We use `File.getContent` recursively to read the content of the files. Since the files are nested (e.g.,  "ShaderChunk/alphahash_fragment.glsl.js"), we call `File.getContent` three times to get the content of the innermost file.

**How to Use:**

You can access the shader chunk content using the `ShaderChunk` class directly. For example:


var alphahashFragment = ShaderChunk.alphahash_fragment;