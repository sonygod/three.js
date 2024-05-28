package three.js.src.renderers.shaders.ShaderChunk;

class AlphatestFragment {
    public function new() {}

    public static function fragment(diffuseColor:Single, alphaTest:Float):Void {
        if (#ifdef USE_ALPHATEST) {
            if (#ifdef ALPHA_TO_COVERAGE) {
                diffuseColor.a = smoothstep(alphaTest, alphaTest + fwidth(diffuseColor.a), diffuseColor.a);
                if (diffuseColor.a == 0.0) {
                    // discard equivalent in Haxe is not applicable, as Haxe doesn't have a direct equivalent to GLSL's discard keyword
                    // In Haxe, you would typically use an if statement to skip the rest of the shader code
                    // For the sake of this example, we'll use a debug trace to indicate that the fragment should be discarded
                    trace("Discard");
                }
            } else {
                if (diffuseColor.a < alphaTest) {
                    // discard equivalent in Haxe is not applicable, as Haxe doesn't have a direct equivalent to GLSL's discard keyword
                    // In Haxe, you would typically use an if statement to skip the rest of the shader code
                    // For the sake of this example, we'll use a debug trace to indicate that the fragment should be discarded
                    trace("Discard");
                }
            }
        }
    }
}