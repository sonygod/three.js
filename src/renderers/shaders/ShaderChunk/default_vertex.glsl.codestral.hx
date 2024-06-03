class DefaultVertexShader {
    public static function getShader(): String {
        return "void main() {\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n}";
    }
}