package three.js.src.renderers.shaders.ShaderLib;

import three.js.src.renderers.shaders.ShaderChunk.common;
import three.js.src.renderers.shaders.ShaderChunk.uv_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.color_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.displacementmap_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.envmap_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.fog_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.normal_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.morphtarget_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.skinning_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.shadowmap_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.logdepthbuf_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.clipping_planes_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.batching_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.uv_vertex;
import three.js.src.renderers.shaders.ShaderChunk.color_vertex;
import three.js.src.renderers.shaders.ShaderChunk.morphinstance_vertex;
import three.js.src.renderers.shaders.ShaderChunk.morphcolor_vertex;
import three.js.src.renderers.shaders.ShaderChunk.batching_vertex;
import three.js.src.renderers.shaders.ShaderChunk.beginnormal_vertex;
import three.js.src.renderers.shaders.ShaderChunk.morphnormal_vertex;
import three.js.src.renderers.shaders.ShaderChunk.skinbase_vertex;
import three.js.src.renderers.shaders.ShaderChunk.skinnormal_vertex;
import three.js.src.renderers.shaders.ShaderChunk.defaultnormal_vertex;
import three.js.src.renderers.shaders.ShaderChunk.normal_vertex;
import three.js.src.renderers.shaders.ShaderChunk.begin_vertex;
import three.js.src.renderers.shaders.ShaderChunk.morphtarget_vertex;
import three.js.src.renderers.shaders.ShaderChunk.skinning_vertex;
import three.js.src.renderers.shaders.ShaderChunk.displacementmap_vertex;
import three.js.src.renderers.shaders.ShaderChunk.project_vertex;
import three.js.src.renderers.shaders.ShaderChunk.logdepthbuf_vertex;
import three.js.src.renderers.shaders.ShaderChunk.clipping_planes_vertex;
import three.js.src.renderers.shaders.ShaderChunk.worldpos_vertex;
import three.js.src.renderers.shaders.ShaderChunk.envmap_vertex;
import three.js.src.renderers.shaders.ShaderChunk.shadowmap_vertex;
import three.js.src.renderers.shaders.ShaderChunk.fog_vertex;
import three.js.src.renderers.shaders.ShaderChunk.packing;
import three.js.src.renderers.shaders.ShaderChunk.dithering_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.color_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.uv_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.map_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphamap_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphatest_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphahash_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.aomap_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.lightmap_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.emissivemap_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.envmap_common_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.envmap_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.fog_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.bsdfs;
import three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin;
import three.js.src.renderers.shaders.ShaderChunk.normal_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.lights_lambert_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.shadowmap_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.bumpmap_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.normalmap_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.specularmap_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.logdepthbuf_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.clipping_planes_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.clipping_planes_fragment;
import three.js.src.renderers.shaders.ShaderChunk.logdepthbuf_fragment;
import three.js.src.renderers.shaders.ShaderChunk.map_fragment;
import three.js.src.renderers.shaders.ShaderChunk.color_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphamap_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphatest_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphahash_fragment;
import three.js.src.renderers.shaders.ShaderChunk.specularmap_fragment;
import three.js.src.renderers.shaders.ShaderChunk.normal_fragment_begin;
import three.js.src.renderers.shaders.ShaderChunk.normal_fragment_maps;
import three.js.src.renderers.shaders.ShaderChunk.emissivemap_fragment;
import three.js.src.renderers.shaders.ShaderChunk.lights_lambert_fragment;
import three.js.src.renderers.shaders.ShaderChunk.lights_fragment_begin;
import three.js.src.renderers.shaders.ShaderChunk.lights_fragment_maps;
import three.js.src.renderers.shaders.ShaderChunk.lights_fragment_end;
import three.js.src.renderers.shaders.ShaderChunk.aomap_fragment;
import three.js.src.renderers.shaders.ShaderChunk.envmap_fragment;
import three.js.src.renderers.shaders.ShaderChunk.opaque_fragment;
import three.js.src.renderers.shaders.ShaderChunk.tonemapping_fragment;
import three.js.src.renderers.shaders.ShaderChunk.colorspace_fragment;
import three.js.src.renderers.shaders.ShaderChunk.fog_fragment;
import three.js.src.renderers.shaders.ShaderChunk.premultiplied_alpha_fragment;
import three.js.src.renderers.shaders.ShaderChunk.dithering_fragment;

class MeshLambertShader {
    public static var vertex:String = "#define LAMBERT\n\n" +
        "varying vec3 vViewPosition;\n\n" +
        common +
        batching_pars_vertex +
        uv_pars_vertex +
        displacementmap_pars_vertex +
        envmap_pars_vertex +
        color_pars_vertex +
        fog_pars_vertex +
        normal_pars_vertex +
        morphtarget_pars_vertex +
        skinning_pars_vertex +
        shadowmap_pars_vertex +
        logdepthbuf_pars_vertex +
        clipping_planes_pars_vertex +
        "\n" +
        "void main() {\n" +
        "\n" +
        "	" + uv_vertex +
        "	" + color_vertex +
        "	" + morphinstance_vertex +
        "	" + morphcolor_vertex +
        "	" + batching_vertex +
        "\n" +
        "	" + beginnormal_vertex +
        "	" + morphnormal_vertex +
        "	" + skinbase_vertex +
        "	" + skinnormal_vertex +
        "	" + defaultnormal_vertex +
        "	" + normal_vertex +
        "\n" +
        "	" + begin_vertex +
        "	" + morphtarget_vertex +
        "	" + skinning_vertex +
        "	" + displacementmap_vertex +
        "	" + project_vertex +
        "	" + logdepthbuf_vertex +
        "	" + clipping_planes_vertex +
        "\n" +
        "	vViewPosition = - mvPosition.xyz;\n" +
        "\n" +
        "	" + worldpos_vertex +
        "	" + envmap_vertex +
        "	" + shadowmap_vertex +
        "	" + fog_vertex +
        "\n" +
        "}\n";

    public static var fragment:String = "#define LAMBERT\n\n" +
        "uniform vec3 diffuse;\n" +
        "uniform vec3 emissive;\n" +
        "uniform float opacity;\n\n" +
        common +
        packing +
        dithering_pars_fragment +
        color_pars_fragment +
        uv_pars_fragment +
        map_pars_fragment +
        alphamap_pars_fragment +
        alphatest_pars_fragment +
        alphahash_pars_fragment +
        aomap_pars_fragment +
        lightmap_pars_fragment +
        emissivemap_pars_fragment +
        envmap_common_pars_fragment +
        envmap_pars_fragment +
        fog_pars_fragment +
        bsdfs +
        lights_pars_begin +
        normal_pars_fragment +
        lights_lambert_pars_fragment +
        shadowmap_pars_fragment +
        bumpmap_pars_fragment +
        normalmap_pars_fragment +
        specularmap_pars_fragment +
        logdepthbuf_pars_fragment +
        clipping_planes_pars_fragment +
        "\n" +
        "void main() {\n" +
        "\n" +
        "	vec4 diffuseColor = vec4( diffuse, opacity );\n" +
        "	" + clipping_planes_fragment +
        "\n" +
        "	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );\n" +
        "	vec3 totalEmissiveRadiance = emissive;\n" +
        "\n" +
        "	" + logdepthbuf_fragment +
        "	" + map_fragment +
        "	" + color_fragment +
        "	" + alphamap_fragment +
        "	" + alphatest_fragment +
        "	" + alphahash_fragment +
        "	" + specularmap_fragment +
        "	" + normal_fragment_begin +
        "	" + normal_fragment_maps +
        "	" + emissivemap_fragment +
        "\n" +
        "	// accumulation\n" +
        "	" + lights_lambert_fragment +
        "	" + lights_fragment_begin +
        "	" + lights_fragment_maps +
        "	" + lights_fragment_end +
        "\n" +
        "	// modulation\n" +
        "	" + aomap_fragment +
        "\n" +
        "	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;\n" +
        "\n" +
        "	" + envmap_fragment +
        "	" + opaque_fragment +
        "	" + tonemapping_fragment +
        "	" + colorspace_fragment +
        "	" + fog_fragment +
        "	" + premultiplied_alpha_fragment +
        "	" + dithering_fragment +
        "\n" +
        "}\n";
}