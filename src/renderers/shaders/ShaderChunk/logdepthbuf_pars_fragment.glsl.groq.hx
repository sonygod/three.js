package three.renderers.shaders.ShaderChunk;

#if (js && (USE_LOGDEPTHBUF == true))

@:glsl("
	uniform float logDepthBufFC;
	varying float vFragDepth;
	varying float vIsPerspective;
")

#end