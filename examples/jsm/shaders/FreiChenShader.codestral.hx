import three.Vector2;

class FreiChenShader {
    public static var name:String = "FreiChenShader";

    public static var uniforms:Map<String, Dynamic> = new Map<String, Dynamic>();
    static {
        uniforms.set("tDiffuse", { value: null });
        uniforms.set("aspect", { value: new Vector2(512, 512) });
    }

    public static var vertexShader:String = "varying vec2 vUv;\n" +
        "void main() {\n" +
        "    vUv = uv;\n" +
        "    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n" +
        "}\n";

    public static var fragmentShader:String = "uniform sampler2D tDiffuse;\n" +
        "varying vec2 vUv;\n" +
        "uniform vec2 aspect;\n" +
        "vec2 texel = vec2( 1.0 / aspect.x, 1.0 / aspect.y );\n" +
        "mat3 G[9];\n" +
        "const mat3 g0 = mat3( 0.3535533845424652, 0, -0.3535533845424652, 0.5, 0, -0.5, 0.3535533845424652, 0, -0.3535533845424652 );\n" +
        "// ... rest of your code ...\n";
}