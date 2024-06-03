class DefaultFragment {
    public static function get():String {
        return """
void main() {
	gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}
""";
    }
}