package three.js.src.renderers.shaders.ShaderChunk;

class OpaqueFragmentGlsl {
    public function new() {}

    public static function getShader():String {
        var shader:String = "";

        shader += "#ifdef OPAQUE\n";
        shader += "diffuseColor.a = 1.0;\n";
        shader += "#endif\n";

        shader += "#ifdef USE_TRANSMISSION\n";
        shader += "diffuseColor.a *= material.transmissionAlpha;\n";
        shader += "#endif\n";

        shader += "gl_FragColor = vec4( outgoingLight, diffuseColor.a );";

        return shader;
    }
}