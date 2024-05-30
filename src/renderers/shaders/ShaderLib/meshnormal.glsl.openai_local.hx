package three.renderers.shaders.ShaderLib;

class MeshNormalGLSL {
    public static inline var vertex = 
        "#define NORMAL\n" +
        "\n" +
        "#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )\n" +
        "\n" +
        "    varying vec3 vViewPosition;\n" +
        "\n" +
        "#endif\n" +
        "\n" +
        "#include <common>\n" +
        "#include <batching_pars_vertex>\n" +
        "#include <uv_pars_vertex>\n" +
        "#include <displacementmap_pars_vertex>\n" +
        "#include <normal_pars_vertex>\n" +
        "#include <morphtarget_pars_vertex>\n" +
        "#include <skinning_pars_vertex>\n" +
        "#include <logdepthbuf_pars_vertex>\n" +
        "#include <clipping_planes_pars_vertex>\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "    #include <uv_vertex>\n" +
        "    #include <batching_vertex>\n" +
        "\n" +
        "    #include <beginnormal_vertex>\n" +
        "    #include <morphinstance_vertex>\n" +
        "    #include <morphnormal_vertex>\n" +
        "    #include <skinbase_vertex>\n" +
        "    #include <skinnormal_vertex>\n" +
        "    #include <defaultnormal_vertex>\n" +
        "    #include <normal_vertex>\n" +
        "\n" +
        "    #include <begin_vertex>\n" +
        "    #include <morphtarget_vertex>\n" +
        "    #include <skinning_vertex>\n" +
        "    #include <displacementmap_vertex>\n" +
        "    #include <project_vertex>\n" +
        "    #include <logdepthbuf_vertex>\n" +
        "    #include <clipping_planes_vertex>\n" +
        "\n" +
        "#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )\n" +
        "\n" +
        "    vViewPosition = - mvPosition.xyz;\n" +
        "\n" +
        "#endif\n" +
        "\n" +
        "}\n";

    public static inline var fragment = 
        "#define NORMAL\n" +
        "\n" +
        "uniform float opacity;\n" +
        "\n" +
        "#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )\n" +
        "\n" +
        "    varying vec3 vViewPosition;\n" +
        "\n" +
        "#endif\n" +
        "\n" +
        "#include <packing>\n" +
        "#include <uv_pars_fragment>\n" +
        "#include <normal_pars_fragment>\n" +
        "#include <bumpmap_pars_fragment>\n" +
        "#include <normalmap_pars_fragment>\n" +
        "#include <logdepthbuf_pars_fragment>\n" +
        "#include <clipping_planes_pars_fragment>\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "    vec4 diffuseColor = vec4( 0.0, 0.0, 0.0, opacity );\n" +
        "\n" +
        "    #include <clipping_planes_fragment>\n" +
        "    #include <logdepthbuf_fragment>\n" +
        "    #include <normal_fragment_begin>\n" +
        "    #include <normal_fragment_maps>\n" +
        "\n" +
        "    gl_FragColor = vec4( packNormalToRGB( normal ), diffuseColor.a );\n" +
        "\n" +
        "    #ifdef OPAQUE\n" +
        "\n" +
        "        gl_FragColor.a = 1.0;\n" +
        "\n" +
        "    #endif\n" +
        "\n" +
        "}\n";
}