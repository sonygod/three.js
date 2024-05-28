package three.shader.chunks;

class MorphTargetVertexChunk {
    public function new() {}

    public static function getVertexShaderCode(?useMorphTargets:Bool = false):String {
        if (useMorphTargets) {
            return '
                #ifdef USE_MORPHTARGETS

                    transformed *= morphTargetBaseInfluence;

                    for (i = 0; i < MORPHTARGETS_COUNT; i++) {
                        if (morphTargetInfluences[i] != 0.0) transformed += getMorph(gl_VertexID, i, 0).xyz * morphTargetInfluences[i];
                    }

                #endif
            ';
        } else {
            return "";
        }
    }
}

Note:

* In Haxe, we don't need to use the `export default` syntax, as we can define a class and a static method to return the shader code.
* The `/* glsl */` comment is not needed in Haxe, as we're generating GLSL code using a string literal.
* The `#ifdef USE_MORPHTARGETS` directive is preserved, as it's a valid GLSL preprocessor directive.
* The `for` loop is preserved, as it's a valid GLSL construct.
* The `getMorph` function is assumed to be defined elsewhere in the shader code; if it's not defined, you'll need to add it to the Haxe code as well.

You can use this Haxe class like this:

var shaderCode:String = MorphTargetVertexChunk.getVertexShaderCode(true);