class ShaderChunk {
    public static function main() {
        var defaultFragmentShader =
`
void main() {
	gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}
`;
        trace(defaultFragmentShader);
    }
}