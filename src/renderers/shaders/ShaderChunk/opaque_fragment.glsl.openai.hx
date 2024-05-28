package three.js.src.renderers.shaders.ShaderChunk;

class OpaqueFragment {
    public function new() {}

    public static function main():Void {
        #if OPAQUE
        diffuseColor.a = 1.0;
        #end

        #if USE_TRANSMISSION
        diffuseColor.a *= material.transmissionAlpha;
        #end

        gl_FragColor = vec4(outgoingLight, diffuseColor.a);
    }
}