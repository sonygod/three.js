package three.js.src.renderers.shaders.ShaderLib;

@:build(macro.ShaderMacro.vertex)
extern class DistanceRGBAVertexShader {
  static var vertex:String = '#define DISTANCE\n\n' +
  'varying vec3 vWorldPosition;\n\n' +
  '#include <common>\n' +
  '#include <batching_pars_vertex>\n' +
  '#include <uv_pars_vertex>\n' +
  '#include <displacementmap_pars_vertex>\n' +
  '#include <morphtarget_pars_vertex>\n' +
  '#include <skinning_pars_vertex>\n' +
  '#include <clipping_planes_pars_vertex>\n\n' +
  'void main() {\n\n' +
  '  #include <uv_vertex>\n\n' +
  '  #include <batching_vertex>\n' +
  '  #include <skinbase_vertex>\n\n' +
  '  #include <morphinstance_vertex>\n\n' +
  '  #ifdef USE_DISPLACEMENTMAP\n\n' +
  '    #include <beginnormal_vertex>\n' +
  '    #include <morphnormal_vertex>\n' +
  '    #include <skinnormal_vertex>\n\n' +
  '  #endif\n\n' +
  '  #include <begin_vertex>\n' +
  '  #include <morphtarget_vertex>\n' +
  '  #include <skinning_vertex>\n' +
  '  #include <displacementmap_vertex>\n' +
  '  #include <project_vertex>\n' +
  '  #include <worldpos_vertex>\n' +
  '  #include <clipping_planes_vertex>\n\n' +
  '  vWorldPosition = worldPosition.xyz;\n' +
  '}\n';
}

@:build(macro.ShaderMacro.fragment)
extern class DistanceRGBAFragmentShader {
  static var fragment:String = '#define DISTANCE\n\n' +
  'uniform vec3 referencePosition;\n' +
  'uniform float nearDistance;\n' +
  'uniform float farDistance;\n' +
  'varying vec3 vWorldPosition;\n\n' +
  '#include <common>\n' +
  '#include <packing>\n' +
  '#include <uv_pars_fragment>\n' +
  '#include <map_pars_fragment>\n' +
  '#include <alphamap_pars_fragment>\n' +
  '#include <alphatest_pars_fragment>\n' +
  '#include <alphahash_pars_fragment>\n' +
  '#include <clipping_planes_pars_fragment>\n\n' +
  'void main () {\n\n' +
  '  vec4 diffuseColor = vec4( 1.0 );\n' +
  '  #include <clipping_planes_fragment>\n\n' +
  '  #include <map_fragment>\n' +
  '  #include <alphamap_fragment>\n' +
  '  #include <alphatest_fragment>\n' +
  '  #include <alphahash_fragment>\n\n' +
  '  float dist = length( vWorldPosition - referencePosition );\n' +
  '  dist = ( dist - nearDistance ) / ( farDistance - nearDistance );\n' +
  '  dist = saturate( dist ); // clamp to [ 0, 1 ]\n\n' +
  '  gl_FragColor = packDepthToRGBA( dist );\n' +
  '}\n';
}