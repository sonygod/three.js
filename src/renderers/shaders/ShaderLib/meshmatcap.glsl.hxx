class ShaderLib {
    static var vertex:String = /* glsl */`
        #define MATCAP

        varying vec3 vViewPosition;

        // Include common, batching_pars_vertex, uv_pars_vertex, color_pars_vertex, 
        // displacementmap_pars_vertex, fog_pars_vertex, normal_pars_vertex, 
        // morphtarget_pars_vertex, skinning_pars_vertex

        void main() {

            // Include uv_vertex, color_vertex, morphinstance_vertex, morphcolor_vertex, 
            // batching_vertex, beginnormal_vertex, morphnormal_vertex, skinbase_vertex, 
            // skinnormal_vertex, defaultnormal_vertex, normal_vertex, begin_vertex, 
            // morphtarget_vertex, skinning_vertex, displacementmap_vertex, project_vertex, 
            // logdepthbuf_vertex, clipping_planes_vertex, fog_vertex

            vViewPosition = - mvPosition.xyz;

        }
    `;

    static var fragment:String = /* glsl */`
        #define MATCAP

        uniform vec3 diffuse;
        uniform float opacity;
        uniform sampler2D matcap;

        varying vec3 vViewPosition;

        // Include common, dithering_pars_fragment, color_pars_fragment, uv_pars_fragment, 
        // map_pars_fragment, alphamap_pars_fragment, alphatest_pars_fragment, 
        // alphahash_pars_fragment, fog_pars_fragment, normal_pars_fragment, 
        // bumpmap_pars_fragment, normalmap_pars_fragment, logdepthbuf_pars_fragment, 
        // clipping_planes_pars_fragment

        void main() {

            vec4 diffuseColor = vec4( diffuse, opacity );
            // Include clipping_planes_fragment, logdepthbuf_fragment, map_fragment, 
            // color_fragment, alphamap_fragment, alphatest_fragment, alphahash_fragment, 
            // normal_fragment_begin, normal_fragment_maps

            vec3 viewDir = normalize( vViewPosition );
            vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
            vec3 y = cross( viewDir, x );
            vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5; // 0.495 to remove artifacts caused by undersized matcap disks

            #ifdef USE_MATCAP

                vec4 matcapColor = texture2D( matcap, uv );

            #else

                vec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 ); // default if matcap is missing

            #endif

            vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;

            // Include opaque_fragment, tonemapping_fragment, colorspace_fragment, 
            // fog_fragment, premultiplied_alpha_fragment, dithering_fragment

        }
    `;
}