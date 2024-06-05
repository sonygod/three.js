package three.shaderlib;

import haxe.macro.Expr;

class DepthShader {
  public static var vertexShader:String = "
    #include <common>
    #include <batching_pars_vertex>
    #include <uv_pars_vertex>
    #include <displacementmap_pars_vertex>
    #include <morphtarget_pars_vertex>
    #include <skinning_pars_vertex>
    #include <logdepthbuf_pars_vertex>
    #include <clipping_planes_pars_vertex>

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
  ";

  public static var fragmentShader:String = "
    #ifdef DEPTH_PACKING_3200
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
      vec4 diffuseColor = vec4(1.0);
      #include <clipping_planes_fragment>

      #ifdef DEPTH_PACKING_3200
        diffuseColor.a = opacity;
      #endif

      #include <map_fragment>
      #include <alphamap_fragment>
      #include <alphatest_fragment>
      #include <alphahash_fragment>

      #include <logdepthbuf_fragment>

      float fragCoordZ = 0.5 * vHighPrecisionZW[0] / vHighPrecisionZW[1] + 0.5;

      #ifdef DEPTH_PACKING_3200
        gl_FragColor = vec4(vec3(1.0 - fragCoordZ), opacity);
      #elif DEPTH_PACKING_3201
        gl_FragColor = packDepthToRGBA(fragCoordZ);
      #endif
    }
  ";
}