class ShaderLib {
    public static var vertex:String;
    public static var fragment:String;

    static function init() {
        vertex = """
        // PHONG

        var vViewPosition:Vec3;

        // Included files would go here
        // <common>
        // <batching_pars_vertex>
        // ...

        function main() {

            // Included files would go here
            // <uv_vertex>
            // <color_vertex>
            // ...

            vViewPosition = - mvPosition.xyz;

            // Included files would go here
            // <worldpos_vertex>
            // <envmap_vertex>
            // ...

        }
        """;

        fragment = """
        // PHONG

        uniform var diffuse:Vec3;
        uniform var emissive:Vec3;
        uniform var specular:Vec3;
        uniform var shininess:Float;
        uniform var opacity:Float;

        // Included files would go here
        // <common>
        // <packing>
        // ...

        function main() {

            var diffuseColor:Vec4 = Vec4( diffuse, opacity );
            // Included files would go here
            // <clipping_planes_fragment>

            var reflectedLight = ReflectedLight( Vec3( 0.0 ), Vec3( 0.0 ), Vec3( 0.0 ), Vec3( 0.0 ) );
            var totalEmissiveRadiance = emissive;

            // Included files would go here
            // <logdepthbuf_fragment>
            // <map_fragment>
            // ...

            // accumulation
            // <lights_phong_fragment>
            // <lights_fragment_begin>
            // ...

            // modulation
            // <aomap_fragment>

            var outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;

            // Included files would go here
            // <envmap_fragment>
            // <opaque_fragment>
            // ...

        }
        """;
    }
}