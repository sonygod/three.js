// File path: three/src/renderers/shaders/ShaderLib/depth.glsl.hx

package three.renderers.shaders.ShaderLib;

extern class ShaderChunk {
    public static var common: String;
    public static var batching_pars_vertex: String;
    public static var uv_pars_vertex: String;
    public static var displacementmap_pars_vertex: String;
    public static var morphtarget_pars_vertex: String;
    public static var skinning_pars_vertex: String;
    public static var logdepthbuf_pars_vertex: String;
    public static var clipping_planes_pars_vertex: String;
    public static var uv_vertex: String;
    public static var batching_vertex: String;
    public static var skinbase_vertex: String;
    public static var morphinstance_vertex: String;
    public static var beginnormal_vertex: String;
    public static var morphnormal_vertex: String;
    public static var skinnormal_vertex: String;
    public static var begin_vertex: String;
    public static var morphtarget_vertex: String;
    public static var skinning_vertex: String;
    public static var displacementmap_vertex: String;
    public static var project_vertex: String;
    public static var logdepthbuf_vertex: String;
    public static var clipping_planes_vertex: String;
    public static var packing: String;
    public static var uv_pars_fragment: String;
    public static var map_pars_fragment: String;
    public static var alphamap_pars_fragment: String;
    public static var alphatest_pars_fragment: String;
    public static var alphahash_pars_fragment: String;
    public static var logdepthbuf_pars_fragment: String;
    public static var clipping_planes_pars_fragment: String;
    public static var clipping_planes_fragment: String;
    public static var map_fragment: String;
    public static var alphamap_fragment: String;
    public static var alphatest_fragment: String;
    public static var alphahash_fragment: String;
    public static var logdepthbuf_fragment: String;
    public static function packDepthToRGBA( depth: Float ): Vec4;
}

class DepthShader {
    public static var vertex: String = '
        #include <common>
        #include <batching_pars_vertex>
        #include <uv_pars_vertex>
        #include <displacementmap_pars_vertex>
        #include <morphtarget_pars_vertex>
        #include <skinning_pars_vertex>
        #include <logdepthbuf_pars_vertex>
        #include <clipping_planes_pars_vertex>

        // This is used for computing an equivalent of gl_FragCoord.z that is as high precision as possible.
        // Some platforms compute gl_FragCoord at a lower precision which makes the manually computed value better for
        // depth-based postprocessing effects. Reproduced on iPad with A10 processor / iPadOS 13.3.1.
        varying vec2 vHighPrecisionZW;

        void main() {
            #include <uv_vertex>
            #include <batching_vertex>
            #include <skinbase_vertex>
            #include <morphinstance_vertex>

            #ifdef USE_DISPLACEMENTMAP
                #include <beginnormal_vertex>
                #include <morphnormal_vertex>
                #include <skinnormal_vertex>
            #endif

            #include <begin_vertex>
            #include <morphtarget_vertex>
            #include <skinning_vertex>
            #include <displacementmap_vertex>
            #include <project_vertex>
            #include <logdepthbuf_vertex>
            #include <clipping_planes_vertex>

            vHighPrecisionZW = gl_Position.zw;
        }
    ';

    public static var fragment: String = '
        #if DEPTH_PACKING == 3200
            uniform float opacity;
        #endif

        #include <common>
        #include <packing>
        #include <uv_pars_fragment>
        #include <map_pars_fragment>
        #include <alphamap_pars_fragment>
        #include <alphatest_pars_fragment>
        #include <alphahash_pars_fragment>
        #include <logdepthbuf_pars_fragment>
        #include <clipping_planes_pars_fragment>

        varying vec2 vHighPrecisionZW;

        void main() {
            vec4 diffuseColor = vec4( 1.0 );
            #include <clipping_planes_fragment>

            #if DEPTH_PACKING == 3200
                diffuseColor.a = opacity;
            #endif

            #include <map_fragment>
            #include <alphamap_fragment>
            #include <alphatest_fragment>
            #include <alphahash_fragment>
            #include <logdepthbuf_fragment>

            // Higher precision equivalent of gl_FragCoord.z. This assumes depthRange has been left to its default values.
            float fragCoordZ = 0.5 * vHighPrecisionZW[0] / vHighPrecisionZW[1] + 0.5;

            #if DEPTH_PACKING == 3200
                gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );
            #elif DEPTH_PACKING == 3201
                gl_FragColor = packDepthToRGBA( fragCoordZ );
            #endif
        }
    ';
}