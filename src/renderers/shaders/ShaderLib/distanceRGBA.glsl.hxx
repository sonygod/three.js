class ShaderLib {
    static var vertex:String = /* glsl */`
        #define DISTANCE

        varying vec3 vWorldPosition;

        // include common, batching_pars_vertex, uv_pars_vertex, displacementmap_pars_vertex, morphtarget_pars_vertex, skinning_pars_vertex, clipping_planes_pars_vertex

        void main() {

            // include uv_vertex, batching_vertex, skinbase_vertex, morphinstance_vertex

            #ifdef USE_DISPLACEMENTMAP

                // include beginnormal_vertex, morphnormal_vertex, skinnormal_vertex

            #endif

            // include begin_vertex, morphtarget_vertex, skinning_vertex, displacementmap_vertex, project_vertex, worldpos_vertex, clipping_planes_vertex

            vWorldPosition = worldPosition.xyz;

        }
    `;

    static var fragment:String = /* glsl */`
        #define DISTANCE

        uniform vec3 referencePosition;
        uniform float nearDistance;
        uniform float farDistance;
        varying vec3 vWorldPosition;

        // include common, packing, uv_pars_fragment, map_pars_fragment, alphamap_pars_fragment, alphatest_pars_fragment, alphahash_pars_fragment, clipping_planes_pars_fragment

        void main () {

            vec4 diffuseColor = vec4( 1.0 );
            // include clipping_planes_fragment

            // include map_fragment, alphamap_fragment, alphatest_fragment, alphahash_fragment

            float dist = length( vWorldPosition - referencePosition );
            dist = ( dist - nearDistance ) / ( farDistance - nearDistance );
            dist = clamp( dist, 0.0, 1.0 ); // clamp to [ 0, 1 ]

            gl_FragColor = packDepthToRGBA( dist );

        }
    `;
}