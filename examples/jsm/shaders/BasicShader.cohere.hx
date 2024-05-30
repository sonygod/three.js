package;

class BasicShader {
    public var name: String = 'BasicShader';
    public var uniforms: { } = { };

    public static var vertexShader = """
        void main() {
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    """;

    public static var fragmentShader = """
        void main() {
            gl_FragColor = vec4( 1.0, 0.0, 0.0, 0.5 );
        }
    """;
}