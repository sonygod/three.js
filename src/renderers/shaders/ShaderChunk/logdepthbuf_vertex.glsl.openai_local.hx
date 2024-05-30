// File path: three.js/src/renderers/shaders/ShaderChunk/logdepthbuf_vertex.glsl.hx

#if glsl
#ifdef USE_LOGDEPTHBUF

	vFragDepth = 1.0 + gl_Position.w;
	vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );

#endif
#end