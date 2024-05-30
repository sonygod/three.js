package three.js.src.renderers.shaders.ShaderLib;

import three.js.src.renderers.shaders.ShaderChunk.common;
import three.js.src.renderers.shaders.ShaderChunk.batching_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.uv_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.displacementmap_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.morphtarget_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.skinning_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.logdepthbuf_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.clipping_planes_pars_vertex;
import three.js.src.renderers.shaders.ShaderChunk.uv_vertex;
import three.js.src.renderers.shaders.ShaderChunk.batching_vertex;
import three.js.src.renderers.shaders.ShaderChunk.skinbase_vertex;
import three.js.src.renderers.shaders.ShaderChunk.morphinstance_vertex;
import three.js.src.renderers.shaders.ShaderChunk.beginnormal_vertex;
import three.js.src.renderers.shaders.ShaderChunk.morphnormal_vertex;
import three.js.src.renderers.shaders.ShaderChunk.skinnormal_vertex;
import three.js.src.renderers.shaders.ShaderChunk.begin_vertex;
import three.js.src.renderers.shaders.ShaderChunk.morphtarget_vertex;
import three.js.src.renderers.shaders.ShaderChunk.skinning_vertex;
import three.js.src.renderers.shaders.ShaderChunk.displacementmap_vertex;
import three.js.src.renderers.shaders.ShaderChunk.project_vertex;
import three.js.src.renderers.shaders.ShaderChunk.logdepthbuf_vertex;
import three.js.src.renderers.shaders.ShaderChunk.clipping_planes_vertex;
import three.js.src.renderers.shaders.ShaderChunk.packing;
import three.js.src.renderers.shaders.ShaderChunk.map_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphamap_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphatest_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphahash_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.logdepthbuf_pars_fragment;
import three.js.src.renderers.shaders.ShaderChunk.clipping_planes_fragment;
import three.js.src.renderers.shaders.ShaderChunk.map_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphamap_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphatest_fragment;
import three.js.src.renderers.shaders.ShaderChunk.alphahash_fragment;
import three.js.src.renderers.shaders.ShaderChunk.logdepthbuf_fragment;
import three.js.src.renderers.shaders.ShaderChunk.packDepthToRGBA;

class Depth {
    static var vertex = [
        "#include <common>",
        "#include <batching_pars_vertex>",
        "#include <uv_pars_vertex>",
        "#include <displacementmap_pars_vertex>",
        "#include <morphtarget_pars_vertex>",
        "#include <skinning_pars_vertex>",
        "#include <logdepthbuf_pars_vertex>",
        "#include <clipping_planes_pars_vertex>",
        "",
        "// This is used for computing an equivalent of gl_FragCoord.z that is as high precision as possible.",
        "// Some platforms compute gl_FragCoord at a lower precision which makes the manually computed value better for",
        "// depth-based postprocessing effects. Reproduced on iPad with A10 processor / iPadOS 13.3.1.",
        "varying vec2 vHighPrecisionZW;",
        "",
        "void main() {",
        "",
        "	#include <uv_vertex>",
        "",
        "	#include <batching_vertex>",
        "	#include <skinbase_vertex>",
        "",
        "	#include <morphinstance_vertex>",
        "",
        "	#ifdef USE_DISPLACEMENTMAP",
        "",
        "		#include <beginnormal_vertex>",
        "		#include <morphnormal_vertex>",
        "		#include <skinnormal_vertex>",
        "",
        "	#endif",
        "",
        "	#include <begin_vertex>",
        "	#include <morphtarget_vertex>",
        "	#include <skinning_vertex>",
        "	#include <displacementmap_vertex>",
        "	#include <project_vertex>",
        "	#include <logdepthbuf_vertex>",
        "	#include <clipping_planes_vertex>",
        "",
        "	vHighPrecisionZW = gl_Position.zw;",
        "",
        "}"
    ].join("\n");

    static var fragment = [
        "#if DEPTH_PACKING == 3200",
        "",
        "	uniform float opacity;",
        "",
        "#endif",
        "",
        "#include <common>",
        "#include <packing>",
        "#include <uv_pars_fragment>",
        "#include <map_pars_fragment>",
        "#include <alphamap_pars_fragment>",
        "#include <alphatest_pars_fragment>",
        "#include <alphahash_pars_fragment>",
        "#include <logdepthbuf_pars_fragment>",
        "#include <clipping_planes_pars_fragment>",
        "",
        "varying vec2 vHighPrecisionZW;",
        "",
        "void main() {",
        "",
        "	vec4 diffuseColor = vec4( 1.0 );",
        "	#include <clipping_planes_fragment>",
        "",
        "	#if DEPTH_PACKING == 3200",
        "",
        "		diffuseColor.a = opacity;",
        "",
        "	#endif",
        "",
        "	#include <map_fragment>",
        "	#include <alphamap_fragment>",
        "	#include <alphatest_fragment>",
        "	#include <alphahash_fragment>",
        "",
        "	#include <logdepthbuf_fragment>",
        "",
        "	// Higher precision equivalent of gl_FragCoord.z. This assumes depthRange has been left to its default values.",
        "	float fragCoordZ = 0.5 * vHighPrecisionZW[0] / vHighPrecisionZW[1] + 0.5;",
        "",
        "	#if DEPTH_PACKING == 3200",
        "",
        "		gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );",
        "",
        "	#elif DEPTH_PACKING == 3201",
        "",
        "		gl_FragColor = packDepthToRGBA( fragCoordZ );",
        "",
        "	#endif",
        "",
        "}"
    ].join("\n");
}