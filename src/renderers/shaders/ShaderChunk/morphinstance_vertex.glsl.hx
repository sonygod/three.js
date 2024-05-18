@:glsl
class MorphInstanceVertex {
    @:global @:const var MORPHTARGETS_COUNT:Int;

    public function new() {}

    @:vertex
    public function vertex() {
        #ifdef USE_INSTANCING_MORPH
        var morphTargetInfluences:Array<Float> = new Array<Float>(MORPHTARGETS_COUNT);

        var morphTargetBaseInfluence:Float = texture2D(morphTexture, vec2(0, instanceID)).r;

        for (i in 0...MORPHTARGETS_COUNT) {
            morphTargetInfluences[i] = texture2D(morphTexture, vec2(i + 1, instanceID)).r;
        }
        #end
    }
}