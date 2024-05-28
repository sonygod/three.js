#if openfl_gl && openfl_desktop

var morphTargetInfluences:Array<Float> = [];

var morphTargetBaseInfluence:Float = morphTexture.getPixel32(0, gl_InstanceID).r;

for (i in 0...MorphTargetsCount) {
	morphTargetInfluences.push(morphTexture.getPixel32(i + 1, gl_InstanceID).r);
}

#end