package three.renderers.shaders.ShaderLib;

class MeshLambertGlsl {
    public static final vertex:String = 
        '#define LAMBERT\n' +
        '\n' +
        'varying vec3 vViewPosition;\n' +
        '\n' +
        '#include <common>\n' +
        '#include <batching_pars_vertex>\n' +
        '#include <uv_pars_vertex>\n' +
        '#include <displacementmap_pars_vertex>\n' +
        '#include <envmap_pars_vertex>\n' +
        '#include <color_pars_vertex>\n' +
        '#include <fog_pars_vertex>\n' +
        '#include <normal_pars_vertex>\n' +
        '#include <morphtarget_pars_vertex>\n' +
        '#include <skinning_pars_vertex>\n' +
        '#include <shadowmap_pars_vertex>\n' +
        '#include <logdepthbuf_pars_vertex>\n' +
        '#include <clipping_planes_pars_vertex>\n' +
        '\n' +
        'void main() {\n' +
        '\n' +
        '    #include <uv_vertex>\n' +
        '    #include <color_vertex>\n' +
        '    #include <morphinstance_vertex>\n' +
        '    #include <morphcolor_vertex>\n' +
        '    #include <batching_vertex>\n' +
        '\n' +
        '    #include <beginnormal_vertex>\n' +
        '    #include <morphnormal_vertex>\n' +
        '    #include <skinbase_vertex>\n' +
        '    #include <skinnormal_vertex>\n' +
        '    #include <defaultnormal_vertex>\n' +
        '    #include <normal_vertex>\n' +
        '\n' +
        '    #include <begin_vertex>\n' +
        '    #include <morphtarget_vertex>\n' +
        '    #include <skinning_vertex>\n' +
        '    #include <displacementmap_vertex>\n' +
        '    #include <project_vertex>\n' +
        '    #include <logdepthbuf_vertex>\n' +
        '    #include <clipping_planes_vertex>\n' +
        '\n' +
        '    vViewPosition = - mvPosition.xyz;\n' +
        '\n' +
        '    #include <worldpos_vertex>\n' +
        '    #include <envmap_vertex>\n' +
        '    #include <shadowmap_vertex>\n' +
        '    #include <fog_vertex>\n' +
        '\n' +
        '}\n';

    public static final fragment:String = 
        '#define LAMBERT\n' +
        '\n' +
        'uniform vec3 diffuse;\n' +
        'uniform vec3 emissive;\n' +
        'uniform float opacity;\n' +
        '\n' +
        '#include <common>\n' +
        '#include <packing>\n' +
        '#include <dithering_pars_fragment>\n' +
        '#include <color_pars_fragment>\n' +
        '#include <uv_pars_fragment>\n' +
        '#include <map_pars_fragment>\n' +
        '#include <alphamap_pars_fragment>\n' +
        '#include <alphatest_pars_fragment>\n' +
        '#include <alphahash_pars_fragment>\n' +
        '#include <aomap_pars_fragment>\n' +
        '#include <lightmap_pars_fragment>\n' +
        '#include <emissivemap_pars_fragment>\n' +
        '#include <envmap_common_pars_fragment>\n' +
        '#include <envmap_pars_fragment>\n' +
        '#include <fog_pars_fragment>\n' +
        '#include <bsdfs>\n' +
        '#include <lights_pars_begin>\n' +
        '#include <normal_pars_fragment>\n' +
        '#include <lights_lambert_pars_fragment>\n' +
        '#include <shadowmap_pars_fragment>\n' +
        '#include <bumpmap_pars_fragment>\n' +
        '#include <normalmap_pars_fragment>\n' +
        '#include <specularmap_pars_fragment>\n' +
        '#include <logdepthbuf_pars_fragment>\n' +
        '#include <clipping_planes_pars_fragment>\n' +
        '\n' +
        'void main() {\n' +
        '\n' +
        '    vec4 diffuseColor = vec4( diffuse, opacity );\n' +
        '    #include <clipping_planes_fragment>\n' +
        '\n' +
        '    ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );\n' +
        '    vec3 totalEmissiveRadiance = emissive;\n' +
        '\n' +
        '    #include <logdepthbuf_fragment>\n' +
        '    #include <map_fragment>\n' +
        '    #include <color_fragment>\n' +
        '    #include <alphamap_fragment>\n' +
        '    #include <alphatest_fragment>\n' +
        '    #include <alphahash_fragment>\n' +
        '    #include <specularmap_fragment>\n' +
        '    #include <normal_fragment_begin>\n' +
        '    #include <normal_fragment_maps>\n' +
        '    #include <emissivemap_fragment>\n' +
        '\n' +
        '    // accumulation\n' +
        '    #include <lights_lambert_fragment>\n' +
        '    #include <lights_fragment_begin>\n' +
        '    #include <lights_fragment_maps>\n' +
        '    #include <lights_fragment_end>\n' +
        '\n' +
        '    // modulation\n' +
        '    #include <aomap_fragment>\n' +
        '\n' +
        '    vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;\n' +
        '\n' +
        '    #include <envmap_fragment>\n' +
        '    #include <opaque_fragment>\n' +
        '    #include <tonemapping_fragment>\n' +
        '    #include <colorspace_fragment>\n' +
        '    #include <fog_fragment>\n' +
        '    #include <premultiplied_alpha_fragment>\n' +
        '    #include <dithering_fragment>\n' +
        '\n' +
        '}\n';
}