#ifdef USE_INSTANCING_MORPH

var morphTargetInfluences:Array<Float> = new Array<Float>();

var morphTargetBaseInfluence:Float = Std.parseFloat(texelFetch(morphTexture, ivec2(0, gl_InstanceID), 0).r);

for (var i:Int = 0; i < MORPHTARGETS_COUNT; i++) {
    morphTargetInfluences[i] = Std.parseFloat(texelFetch(morphTexture, ivec2(i + 1, gl_InstanceID), 0).r);
}

#end