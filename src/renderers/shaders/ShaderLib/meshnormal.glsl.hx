package three.shaderlib.meshnormal;

import haxe.macro.Expr;
import haxe.macro.Context;

class MeshNormalShader {
    public static var vertexShader = [
        #if (defined FLAT_SHADED || defined USE_BUMPMAP || defined USE_NORMALMAP_TANGENTSPACE)
        "varying vec3 vViewPosition;",
        #end

        #include "common.glsl"
        #include "batching_pars_vertex.glsl"
        #include "uv_pars_vertex.glsl"
        #include "displacementmap_pars_vertex.glsl"
        #include "normal_pars_vertex.glsl"
        #include "morphtarget_pars_vertex.glsl"
        #include "skinning_pars_vertex.glsl"
        #include "logdepthbuf_pars_vertex.glsl"
        #include "clipping_planes_pars_vertex.glsl"

        "void main() {",
        #include "uv_vertex.glsl"
        #include "batching_vertex.glsl"
        #include "beginnormal_vertex.glsl"
        #include "morphinstance_vertex.glsl"
        #include "morphnormal_vertex.glsl"
        #include "skinbase_vertex.glsl"
        #include "skinnormal_vertex.glsl"
        #include "defaultnormal_vertex.glsl"
        #include "normal_vertex.glsl"
        #include "begin_vertex.glsl"
        #include "morphtarget_vertex.glsl"
        #include "skinning_vertex.glsl"
        #include "displacementmap_vertex.glsl"
        #include "project_vertex.glsl"
        #include "logdepthbuf_vertex.glsl"
        #include "clipping_planes_vertex.glsl"

        #if (defined FLAT_SHADED || defined USE_BUMPMAP || defined USE_NORMALMAP_TANGENTSPACE)
        "vViewPosition = - mvPosition.xyz;",
        #end
        "}"
    ].join("\n");

    public static var fragmentShader = [
        "#define NORMAL",
        "uniform float opacity;",

        #if (defined FLAT_SHADED || defined USE_BUMPMAP || defined USE_NORMALMAP_TANGENTSPACE)
        "varying vec3 vViewPosition;",
        #end

        #include "packing.glsl"
        #include "uv_pars_fragment.glsl"
        #include "normal_pars_fragment.glsl"
        #include "bumpmap_pars_fragment.glsl"
        #include "normalmap_pars_fragment.glsl"
        #include "logdepthbuf_pars_fragment.glsl"
        #include "clipping_planes_pars_fragment.glsl"

        "void main() {",
        "vec4 diffuseColor = vec4( 0.0, 0.0, 0.0, opacity );",

        #include "clipping_planes_fragment.glsl"
        #include "logdepthbuf_fragment.glsl"
        #include "normal_fragment_begin.glsl"
        #include "normal_fragment_maps.glsl"

        "gl_FragColor = vec4( packNormalToRGB( normal ), diffuseColor.a );",

        #ifdef OPAQUE
        "gl_FragColor.a = 1.0;",
        #end

        "}"
    ].join("\n");
}