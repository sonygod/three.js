package three.js.src.renderers.shaders.ShaderLib;

class Shadow {
    static var vertex: String = "#include <common>\n" +
        "#include <batching_pars_vertex>\n" +
        "#include <fog_pars_vertex>\n" +
        "#include <morphtarget_pars_vertex>\n" +
        "#include <skinning_pars_vertex>\n" +
        "#include <logdepthbuf_pars_vertex>\n" +
        "#include <shadowmap_pars_vertex>\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "	#include <batching_vertex>\n" +
        "\n" +
        "	#include <beginnormal_vertex>\n" +
        "	#include <morphinstance_vertex>\n" +
        "	#include <morphnormal_vertex>\n" +
        "	#include <skinbase_vertex>\n" +
        "	#include <skinnormal_vertex>\n" +
        "	#include <defaultnormal_vertex>\n" +
        "\n" +
        "	#include <begin_vertex>\n" +
        "	#include <morphtarget_vertex>\n" +
        "	#include <skinning_vertex>\n" +
        "	#include <project_vertex>\n" +
        "	#include <logdepthbuf_vertex>\n" +
        "\n" +
        "	#include <worldpos_vertex>\n" +
        "	#include <shadowmap_vertex>\n" +
        "	#include <fog_vertex>\n" +
        "\n" +
        "}";

    static var fragment: String = "uniform vec3 color;\n" +
        "uniform float opacity;\n" +
        "\n" +
        "#include <common>\n" +
        "#include <packing>\n" +
        "#include <fog_pars_fragment>\n" +
        "#include <bsdfs>\n" +
        "#include <lights_pars_begin>\n" +
        "#include <logdepthbuf_pars_fragment>\n" +
        "#include <shadowmap_pars_fragment>\n" +
        "#include <shadowmask_pars_fragment>\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "	#include <logdepthbuf_fragment>\n" +
        "\n" +
        "	gl_FragColor = vec4( color, opacity * ( 1.0 - getShadowMask() ) );\n" +
        "\n" +
        "	#include <tonemapping_fragment>\n" +
        "	#include <colorspace_fragment>\n" +
        "	#include <fog_fragment>\n" +
        "\n" +
        "}";
}