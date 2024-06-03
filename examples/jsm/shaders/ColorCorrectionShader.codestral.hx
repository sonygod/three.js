import three.Vector3;

class ColorCorrectionShader {
    public static var name:String = "ColorCorrectionShader";

    public static var uniforms:haxe.ds.StringMap = new haxe.ds.StringMap();
    static {
        uniforms.set("tDiffuse", { value: null });
        uniforms.set("powRGB", { value: new Vector3(2, 2, 2) });
        uniforms.set("mulRGB", { value: new Vector3(1, 1, 1) });
        uniforms.set("addRGB", { value: new Vector3(0, 0, 0) });
    }

    public static var vertexShader:String = """
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    """;

    public static var fragmentShader:String = """
        uniform sampler2D tDiffuse;
        uniform vec3 powRGB;
        uniform vec3 mulRGB;
        uniform vec3 addRGB;
        varying vec2 vUv;
        void main() {
            gl_FragColor = texture2D(tDiffuse, vUv);
            gl_FragColor.rgb = mulRGB * pow((gl_FragColor.rgb + addRGB), powRGB);
        }
    """;
}