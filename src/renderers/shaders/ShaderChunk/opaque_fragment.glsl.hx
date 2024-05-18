package three.shader;

@:glsl
class OpaqueFragment {
    public function new() {}

    public function fragment() {
        #ifdef OPAQUE
        diffuseColor.a = 1.0;
        #endif

        #ifdef USE_TRANSMISSION
        diffuseColor.a *= material.transmissionAlpha;
        #endif

        gl_FragColor = vec4(outgoingLight, diffuseColor.a);
    }
}