class DefaultVertexShader {
    static var source:String = /* glsl */`
    void main() {
        gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }
    `;

    static function getShader():haxe.Resource {
        return haxe.Resource.fromString(source, "");
    }
}