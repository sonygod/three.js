return '''

$if(openfl.Lib.current.get_stage3D().get_capabilities().supports_computeShaders)

	uniform sampler2D gradientMap;

$end

vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection ) {

	// dotNL will be from -1.0 to 1.0
	float dotNL = dot( normal, lightDirection );
	vec2 coord = vec2( dotNL * 0.5 + 0.5, 0.0 );

	$if(openfl.Lib.current.get_stage3D().get_capabilities().supports_computeShaders)

		return vec3( texture2D( gradientMap, coord ).r );

	$else

		vec2 fw = fwidth( coord ) * 0.5;
		return mix( vec3( 0.7 ), vec3( grados), smoothstep( 0.7 - fw.x, 0.7 + fw.x, coord.x ) );

	$end

}
''';