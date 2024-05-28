package three.renderers.shaders.ShaderChunk;

class LogDepthBufVertexGLSL {
    public static var shader:String = "
#ifdef USE_LOGDEPTHBUF

	vFragDepth = 1.0 + gl_Position.w;
	vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );

#endif
";
}