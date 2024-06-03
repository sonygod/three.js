class EquirectShader {
    public static var vertex:String = """
    varying vec3 vWorldDirection;

    #include <common>

    void main() {

        vWorldDirection = transformDirection( position, modelMatrix );

        #include <begin_vertex>
        #include <project_vertex>

    }
    """;

    public static var fragment:String = """
    uniform sampler2D tEquirect;

    varying vec3 vWorldDirection;

    #include <common>

    void main() {

        vec3 direction = normalize( vWorldDirection );

        vec2 sampleUV = equirectUv( direction );

        gl_FragColor = texture2D( tEquirect, sampleUV );

        #include <tonemapping_fragment>
        #include <colorspace_fragment>

    }
    """;
}