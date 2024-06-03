class GammaCorrectionShader {
    static var name:String = "GammaCorrectionShader";

    static var uniforms:haxe.ds.StringMap = new haxe.ds.StringMap();
    static function initUniforms() {
        uniforms.set("tDiffuse", { value: null });
    }

    static var vertexShader:String = """
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    """;

    static var fragmentShader:String = """
        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {
            vec4 tex = texture2D( tDiffuse, vUv );

            gl_FragColor = sRGBTransferOETF( tex );
        }
    """;
}

GammaCorrectionShader.initUniforms();

export GammaCorrectionShader;