package three.js.src.renderers.shaders.ShaderLib;

@:build(macro.ShaderLib.buildShader())
extern class MeshPhong {
    static var vertex: String;
    static var fragment: String;
}

@:build(macro.ShaderLib.buildShader())
extern class MeshPhongMacro {
    macro static function buildShader() {
        var vertex = new StringBuf();
        var fragment = new StringBuf();

        vertex.add("#define PHONG\n\n");
        vertex.add("varying vec3 vViewPosition;\n\n");
        vertex.add("#include <common>\n");
        vertex.add("#include <batching_pars_vertex>\n");
        vertex.add("#include <uv_pars_vertex>\n");
        vertex.add("#include <displacementmap_pars_vertex>\n");
        vertex.add("#include <envmap_pars_vertex>\n");
        vertex.add("#include <color_pars_vertex>\n");
        vertex.add("#include <fog_pars_vertex>\n");
        vertex.add("#include <normal_pars_vertex>\n");
        vertex.add("#include <morphtarget_pars_vertex>\n");
        vertex.add("#include <skinning_pars_vertex>\n");
        vertex.add("#include <shadowmap_pars_vertex>\n");
        vertex.add("#include <logdepthbuf_pars_vertex>\n");
        vertex.add("#include <clipping_planes_pars_vertex>\n\n");

        vertex.add("void main() {\n");
        vertex.add("    #include <uv_vertex>\n");
        vertex.add("    #include <color_vertex>\n");
        vertex.add("    #include <morphcolor_vertex>\n");
        vertex.add("    #include <batching_vertex>\n\n");

        vertex.add("    #include <beginnormal_vertex>\n");
        vertex.add("    #include <morphinstance_vertex>\n");
        vertex.add("    #include <morphnormal_vertex>\n");
        vertex.add("    #include <skinbase_vertex>\n");
        vertex.add("    #include <skinnormal_vertex>\n");
        vertex.add("    #include <defaultnormal_vertex>\n");
        vertex.add("    #include <normal_vertex>\n\n");

        vertex.add("    #include <begin_vertex>\n");
        vertex.add("    #include <morphtarget_vertex>\n");
        vertex.add("    #include <skinning_vertex>\n");
        vertex.add("    #include <displacementmap_vertex>\n");
        vertex.add("    #include <project_vertex>\n");
        vertex.add("    #include <logdepthbuf_vertex>\n");
        vertex.add("    #include <clipping_planes_vertex>\n\n");

        vertex.add("    vViewPosition = - mvPosition.xyz;\n\n");

        vertex.add("    #include <worldpos_vertex>\n");
        vertex.add("    #include <envmap_vertex>\n");
        vertex.add("    #include <shadowmap_vertex>\n");
        vertex.add("    #include <fog_vertex>\n");
        vertex.add("}\n");

        fragment.add("#define PHONG\n\n");
        fragment.add("uniform vec3 diffuse;\n");
        fragment.add("uniform vec3 emissive;\n");
        fragment.add("uniform vec3 specular;\n");
        fragment.add("uniform float shininess;\n");
        fragment.add("uniform float opacity;\n\n");
        fragment.add("#include <common>\n");
        fragment.add("#include <packing>\n");
        fragment.add("#include <dithering_pars_fragment>\n");
        fragment.add("#include <color_pars_fragment>\n");
        fragment.add("#include <uv_pars_fragment>\n");
        fragment.add("#include <map_pars_fragment>\n");
        fragment.add("#include <alphamap_pars_fragment>\n");
        fragment.add("#include <alphatest_pars_fragment>\n");
        fragment.add("#include <alphahash_pars_fragment>\n");
        fragment.add("#include <aomap_pars_fragment>\n");
        fragment.add("#include <lightmap_pars_fragment>\n");
        fragment.add("#include <emissivemap_pars_fragment>\n");
        fragment.add("#include <envmap_common_pars_fragment>\n");
        fragment.add("#include <envmap_pars_fragment>\n");
        fragment.add("#include <fog_pars_fragment>\n");
        fragment.add("#include <bsdfs>\n");
        fragment.add("#include <lights_pars_begin>\n");
        fragment.add("#include <normal_pars_fragment>\n");
        fragment.add("#include <lights_phong_pars_fragment>\n");
        fragment.add("#include <shadowmap_pars_fragment>\n");
        fragment.add("#include <bumpmap_pars_fragment>\n");
        fragment.add("#include <normalmap_pars_fragment>\n");
        fragment.add("#include <specularmap_pars_fragment>\n");
        fragment.add("#include <logdepthbuf_pars_fragment>\n");
        fragment.add("#include <clipping_planes_pars_fragment>\n\n");

        fragment.add("void main() {\n");
        fragment.add("    vec4 diffuseColor = vec4( diffuse, opacity );\n");
        fragment.add("    #include <clipping_planes_fragment>\n\n");

        fragment.add("    ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );\n");
        fragment.add("    vec3 totalEmissiveRadiance = emissive;\n\n");

        fragment.add("    #include <logdepthbuf_fragment>\n");
        fragment.add("    #include <map_fragment>\n");
        fragment.add("    #include <color_fragment>\n");
        fragment.add("    #include <alphamap_fragment>\n");
        fragment.add("    #include <alphatest_fragment>\n");
        fragment.add("    #include <alphahash_fragment>\n");
        fragment.add("    #include <specularmap_fragment>\n");
        fragment.add("    #include <normal_fragment_begin>\n");
        fragment.add("    #include <normal_fragment_maps>\n");
        fragment.add("    #include <emissivemap_fragment>\n\n");

        fragment.add("    // accumulation\n");
        fragment.add("    #include <lights_phong_fragment>\n");
        fragment.add("    #include <lights_fragment_begin>\n");
        fragment.add("    #include <lights_fragment_maps>\n");
        fragment.add("    #include <lights_fragment_end>\n\n");

        fragment.add("    // modulation\n");
        fragment.add("    #include <aomap_fragment>\n\n");

        fragment.add("    vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;\n\n");

        fragment.add("    #include <envmap_fragment>\n");
        fragment.add("    #include <opaque_fragment>\n");
        fragment.add("    #include <tonemapping_fragment>\n");
        fragment.add("    #include <colorspace_fragment>\n");
        fragment.add("    #include <fog_fragment>\n");
        fragment.add("    #include <premultiplied_alpha_fragment>\n");
        fragment.add("    #include <dithering_fragment>\n");
        fragment.add("}\n");

        return {
            vertex: vertex.toString(),
            fragment: fragment.toString()
        };
    }
}