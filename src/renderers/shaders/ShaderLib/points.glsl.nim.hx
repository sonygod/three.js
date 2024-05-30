package three.js.src.renderers.shaders.ShaderLib;

class Points {
    public static var vertex:String = "uniform float size;\n" +
        "uniform float scale;\n" +
        "\n" +
        "#include <common>\n" +
        "#include <color_pars_vertex>\n" +
        "#include <fog_pars_vertex>\n" +
        "#include <morphtarget_pars_vertex>\n" +
        "#include <logdepthbuf_pars_vertex>\n" +
        "#include <clipping_planes_pars_vertex>\n" +
        "\n" +
        "#ifdef USE_POINTS_UV\n" +
        "\n" +
        "    varying vec2 vUv;\n" +
        "    uniform mat3 uvTransform;\n" +
        "\n" +
        "#endif\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "    #ifdef USE_POINTS_UV\n" +
        "\n" +
        "        vUv = ( uvTransform * vec3( uv, 1 ) ).xy;\n" +
        "\n" +
        "    #endif\n" +
        "\n" +
        "    #include <color_vertex>\n" +
        "    #include <morphinstance_vertex>\n" +
        "    #include <morphcolor_vertex>\n" +
        "    #include <begin_vertex>\n" +
        "    #include <morphtarget_vertex>\n" +
        "    #include <project_vertex>\n" +
        "\n" +
        "    gl_PointSize = size;\n" +
        "\n" +
        "    #ifdef USE_SIZEATTENUATION\n" +
        "\n" +
        "        bool isPerspective = isPerspectiveMatrix( projectionMatrix );\n" +
        "\n" +
        "        if ( isPerspective ) gl_PointSize *= ( scale / - mvPosition.z );\n" +
        "\n" +
        "    #endif\n" +
        "\n" +
        "    #include <logdepthbuf_vertex>\n" +
        "    #include <clipping_planes_vertex>\n" +
        "    #include <worldpos_vertex>\n" +
        "    #include <fog_vertex>\n" +
        "\n" +
        "}";

    public static var fragment:String = "uniform vec3 diffuse;\n" +
        "uniform float opacity;\n" +
        "\n" +
        "#include <common>\n" +
        "#include <color_pars_fragment>\n" +
        "#include <map_particle_pars_fragment>\n" +
        "#include <alphatest_pars_fragment>\n" +
        "#include <alphahash_pars_fragment>\n" +
        "#include <fog_pars_fragment>\n" +
        "#include <logdepthbuf_pars_fragment>\n" +
        "#include <clipping_planes_pars_fragment>\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "    vec4 diffuseColor = vec4( diffuse, opacity );\n" +
        "    #include <clipping_planes_fragment>\n" +
        "\n" +
        "    vec3 outgoingLight = vec3( 0.0 );\n" +
        "\n" +
        "    #include <logdepthbuf_fragment>\n" +
        "    #include <map_particle_fragment>\n" +
        "    #include <color_fragment>\n" +
        "    #include <alphatest_fragment>\n" +
        "    #include <alphahash_fragment>\n" +
        "\n" +
        "    outgoingLight = diffuseColor.rgb;\n" +
        "\n" +
        "    #include <opaque_fragment>\n" +
        "    #include <tonemapping_fragment>\n" +
        "    #include <colorspace_fragment>\n" +
        "    #include <fog_fragment>\n" +
        "    #include <premultiplied_alpha_fragment>\n" +
        "\n" +
        "}";
}