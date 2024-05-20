class ShaderLib {
    static var vertex:String = /* glsl */`
        uniform float scale;
        attribute float lineDistance;

        varying float vLineDistance;

        // include common, uv_pars_vertex, color_pars_vertex, fog_pars_vertex, morphtarget_pars_vertex, logdepthbuf_pars_vertex, clipping_planes_pars_vertex

        void main() {

            vLineDistance = scale * lineDistance;

            // include uv_vertex, color_vertex, morphinstance_vertex, morphcolor_vertex, begin_vertex, morphtarget_vertex, project_vertex, logdepthbuf_vertex, clipping_planes_vertex, fog_vertex

        }
    `;

    static var fragment:String = /* glsl */`
        uniform vec3 diffuse;
        uniform float opacity;

        uniform float dashSize;
        uniform float totalSize;

        varying float vLineDistance;

        // include common, color_pars_fragment, uv_pars_fragment, map_pars_fragment, fog_pars_fragment, logdepthbuf_pars_fragment, clipping_planes_pars_fragment

        void main() {

            vec4 diffuseColor = vec4( diffuse, opacity );
            // include clipping_planes_fragment

            if ( mod( vLineDistance, totalSize ) > dashSize ) {

                discard;

            }

            vec3 outgoingLight = vec3( 0.0 );

            // include logdepthbuf_fragment, map_fragment, color_fragment

            outgoingLight = diffuseColor.rgb; // simple shader

            // include opaque_fragment, tonemapping_fragment, colorspace_fragment, fog_fragment, premultiplied_alpha_fragment

        }
    `;
}