package three.shader;

#if (js && (USE_COLOR_ALPHA || USE_COLOR || USE_INSTANCING_COLOR || USE_BATCHING_COLOR))

var vColor:Dynamic;

#if USE_COLOR_ALPHA
vColor = vec4(0, 0, 0, 0); // initialize to zero
#else
vColor = vec3(0, 0, 0); // initialize to zero
#end

#end