class LuminosityShader {
    public static var name:String = "LuminosityShader";

    public static var uniforms:Map<String, Dynamic> = new Map<String, Dynamic>();
    static {
        uniforms["tDiffuse"] = { value: null };
    }

    public static var vertexShader:String = """
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    """;

    public static var fragmentShader:String = """
        #include <common>

        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {
            vec4 texel = texture2D( tDiffuse, vUv );
            float l = luminance( texel.rgb );
            gl_FragColor = vec4( l, l, l, texel.w );
        }
    """;
}