import three.Vector2;

class NormalMapShader {
    public static var name: String = "NormalMapShader";

    public static var uniforms: Map<String, Dynamic> = new Map<String, Dynamic>().set("heightMap", {value: null}).set("resolution", {value: new Vector2(512, 512)}).set("scale", {value: new Vector2(1, 1)}).set("height", {value: 0.05});

    public static var vertexShader: String = """
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    """;

    public static var fragmentShader: String = """
        uniform float height;
        uniform vec2 resolution;
        uniform sampler2D heightMap;

        varying vec2 vUv;

        void main() {
            float val = texture2D( heightMap, vUv ).x;

            float valU = texture2D( heightMap, vUv + vec2( 1.0 / resolution.x, 0.0 ) ).x;
            float valV = texture2D( heightMap, vUv + vec2( 0.0, 1.0 / resolution.y ) ).x;

            gl_FragColor = vec4( ( 0.5 * normalize( vec3( val - valU, val - valV, height  ) ) + 0.5 ), 1.0 );
        }
    """;
}