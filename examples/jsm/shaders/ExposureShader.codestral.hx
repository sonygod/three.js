class ExposureShader {
    public var name:String = "ExposureShader";

    public var uniforms:Map<String, Dynamic> = new Map<String, Dynamic>();
    public var vertexShader:String;
    public var fragmentShader:String;

    public function new() {
        uniforms.set("tDiffuse", { value: null });
        uniforms.set("exposure", { value: 1.0 });

        vertexShader = "varying vec2 vUv;\n" +
                        "void main() {\n" +
                        "   vUv = uv;\n" +
                        "   gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);\n" +
                        "}\n";

        fragmentShader = "uniform float exposure;\n" +
                          "uniform sampler2D tDiffuse;\n" +
                          "varying vec2 vUv;\n" +
                          "void main() {\n" +
                          "   gl_FragColor = texture2D(tDiffuse, vUv);\n" +
                          "   gl_FragColor.rgb *= exposure;\n" +
                          "}\n";
    }
}