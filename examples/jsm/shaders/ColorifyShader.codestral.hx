import three.Color;

class ColorifyShader {

    public static var name:String = "ColorifyShader";

    public static var uniforms:haxe.ds.StringMap<Dynamic> = new haxe.ds.StringMap<Dynamic>();
    static {
        uniforms.set('tDiffuse', { value: null });
        uniforms.set('color', { value: new Color(0xffffff) });
    }

    public static var vertexShader:String = """
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    """;

    public static var fragmentShader:String = """
        uniform vec3 color;
        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {
            vec4 texel = texture2D( tDiffuse, vUv );

            vec3 luma = vec3( 0.299, 0.587, 0.114 );
            float v = dot( texel.xyz, luma );

            gl_FragColor = vec4( v * color, texel.w );
        }
    """;

}