return """
	var mvPosition = vec4(transformed, 1.0);

	#if USE_BATCHING

		mvPosition = batchingMatrix * mvPosition;

	#end

	#if USE_INSTANCING

		mvPosition = instanceMatrix * mvPosition;

	#end

	mvPosition = modelViewMatrix * mvPosition;

	gl_Position = projectionMatrix * mvPosition;
""";