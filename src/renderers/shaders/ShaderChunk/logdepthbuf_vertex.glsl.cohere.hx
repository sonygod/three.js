var glsl = """
#ifdef USE_LOGDEPTHBUF

	var vFragDepth = 1.0 + ${gl_Position}.w;
	var vIsPerspective = ${isPerspectiveMatrix(projectionMatrix)};

#endif
""";