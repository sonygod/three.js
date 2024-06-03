class UnpackDepthRGBAShader {
    public static var name:String = "UnpackDepthRGBAShader";

    public static var uniforms:Map<String, Dynamic> = new Map<String, Dynamic>();

    public static var vertexShader:String = """
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    """;

    public static var fragmentShader:String = """
        uniform float opacity;
        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        #include <packing>

        void main() {
            float depth = 1.0 - unpackRGBAToDepth( texture2D( tDiffuse, vUv ) );
            gl_FragColor = vec4( vec3( depth ), opacity );
        }
    """;

    public function new() {
        uniforms.set("tDiffuse", { value: null });
        uniforms.set("opacity", { value: 1.0 });
    }
}