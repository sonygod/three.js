package three.js.src.renderers.shaders.ShaderChunk;

#if (USE_INSTANCING_MORPH)

var morphTargetInfluences = new Array<MORPHTARGETS_COUNT>();

var morphTargetBaseInfluence = texelFetch(morphTexture, ivec2(0, gl_InstanceID), 0).r;

for (i in 0...MORPHTARGETS_COUNT) {
    morphTargetInfluences[i] = texelFetch(morphTexture, ivec2(i + 1, gl_InstanceID), 0).r;
}

#end