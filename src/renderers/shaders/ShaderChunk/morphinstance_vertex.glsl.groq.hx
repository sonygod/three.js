@:glsl
class MorphInstanceVertexShader {
    @:shaderVar
    var morphTargetInfluences:Array<Float> = [for (i in 0...MORPHTARGETS_COUNT) 0.0];

    public function new() {}

    @:shader
    function vertex() {
        #ifdef USE_INSTANCING_MORPH
        var morphTargetBaseInfluence:Float = texelFetch(morphTexture, ivec2(0, gl_InstanceID), 0).r;
        for (i in 0...MORPHTARGETS_COUNT) {
            morphTargetInfluences[i] = texelFetch(morphTexture, ivec2(i + 1, gl_InstanceID), 0).r;
        }
        #end
    }
}