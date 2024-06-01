static public function glsl():String {
  return (
    "#ifdef USE_TRANSMISSION\n\n" +
    "	// Transmission code is based on glTF-Sampler-Viewer\n" +
    "	// https://github.com/KhronosGroup/glTF-Sample-Viewer\n\n" +
    "	uniform float transmission;\n" +
    "	uniform float thickness;\n" +
    "	uniform float attenuationDistance;\n" +
    "	uniform vec3 attenuationColor;\n\n" +
    "	#ifdef USE_TRANSMISSIONMAP\n\n" +
    "		uniform sampler2D transmissionMap;\n\n" +
    "	#endif\n\n" +
    "	#ifdef USE_THICKNESSMAP\n\n" +
    "		uniform sampler2D thicknessMap;\n\n" +
    "	#endif\n\n" +
    "	uniform vec2 transmissionSamplerSize;\n" +
    "	uniform sampler2D transmissionSamplerMap;\n\n" +
    "	uniform mat4 modelMatrix;\n" +
    "	uniform mat4 projectionMatrix;\n\n" +
    "	varying vec3 vWorldPosition;\n\n" +
    "	// Mipped Bicubic Texture Filtering by N8\n" +
    "	// https://www.shadertoy.com/view/Dl2SDW\n\n" +
    "	float w0( float a ) {\n\n" +
    "		return ( 1.0 / 6.0 ) * ( a * ( a * ( - a + 3.0 ) - 3.0 ) + 1.0 );\n\n" +
    "	}\n\n" +
    "	float w1( float a ) {\n\n" +
    "		return ( 1.0 / 6.0 ) * ( a *  a * ( 3.0 * a - 6.0 ) + 4.0 );\n\n" +
    "	}\n\n" +
    "	float w2( float a ){\n\n" +
    "		return ( 1.0 / 6.0 ) * ( a * ( a * ( - 3.0 * a + 3.0 ) + 3.0 ) + 1.0 );\n\n" +
    "	}\n\n" +
    "	float w3( float a ) {\n\n" +
    "		return ( 1.0 / 6.0 ) * ( a * a * a );\n\n" +
    "	}\n\n" +
    "	// g0 and g1 are the two amplitude functions\n" +
    "	float g0( float a ) {\n\n" +
    "		return w0( a ) + w1( a );\n\n" +
    "	}\n\n" +
    "	float g1( float a ) {\n\n" +
    "		return w2( a ) + w3( a );\n\n" +
    "	}\n\n" +
    "	// h0 and h1 are the two offset functions\n" +
    "	float h0( float a ) {\n\n" +
    "		return - 1.0 + w1( a ) / ( w0( a ) + w1( a ) );\n\n" +
    "	}\n\n" +
    "	float h1( float a ) {\n\n" +
    "		return 1.0 + w3( a ) / ( w2( a ) + w3( a ) );\n\n" +
    "	}\n\n" +
    "	vec4 bicubic( sampler2D tex, vec2 uv, vec4 texelSize, float lod ) {\n\n" +
    "		uv = uv * texelSize.zw + 0.5;\n\n" +
    "		vec2 iuv = floor( uv );\n" +
    "		vec2 fuv = fract( uv );\n\n" +
    "		float g0x = g0( fuv.x );\n" +
    "		float g1x = g1( fuv.x );\n" +
    "		float h0x = h0( fuv.x );\n" +
    "		float h1x = h1( fuv.x );\n" +
    "		float h0y = h0( fuv.y );\n" +
    "		float h1y = h1( fuv.y );\n\n" +
    "		vec2 p0 = ( vec2( iuv.x + h0x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;\n" +
    "		vec2 p1 = ( vec2( iuv.x + h1x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;\n" +
    "		vec2 p2 = ( vec2( iuv.x + h0x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;\n" +
    "		vec2 p3 = ( vec2( iuv.x + h1x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;\n\n" +
    "		return g0( fuv.y ) * ( g0x * textureLod( tex, p0, lod ) + g1x * textureLod( tex, p1, lod ) ) +\n" +
    "			g1( fuv.y ) * ( g0x * textureLod( tex, p2, lod ) + g1x * textureLod( tex, p3, lod ) );\n\n" +
    "	}\n\n" +
    "	vec4 textureBicubic( sampler2D sampler, vec2 uv, float lod ) {\n\n" +
    "		vec2 fLodSize = vec2( textureSize( sampler, int( lod ) ) );\n" +
    "		vec2 cLodSize = vec2( textureSize( sampler, int( lod + 1.0 ) ) );\n" +
    "		vec2 fLodSizeInv = 1.0 / fLodSize;\n" +
    "		vec2 cLodSizeInv = 1.0 / cLodSize;\n" +
    "		vec4 fSample = bicubic( sampler, uv, vec4( fLodSizeInv, fLodSize ), floor( lod ) );\n" +
    "		vec4 cSample = bicubic( sampler, uv, vec4( cLodSizeInv, cLodSize ), ceil( lod ) );\n" +
    "		return mix( fSample, cSample, fract( lod ) );\n\n" +
    "	}\n\n" +
    "	vec3 getVolumeTransmissionRay( const in vec3 n, const in vec3 v, const in float thickness, const in float ior, const in mat4 modelMatrix ) {\n\n" +
    "		// Direction of refracted light.\n" +
    "		vec3 refractionVector = refract( - v, normalize( n ), 1.0 / ior );\n\n" +
    "		// Compute rotation-independant scaling of the model matrix.\n" +
    "		vec3 modelScale;\n" +
    "		modelScale.x = length( vec3( modelMatrix[ 0 ].xyz ) );\n" +
    "		modelScale.y = length( vec3( modelMatrix[ 1 ].xyz ) );\n" +
    "		modelScale.z = length( vec3( modelMatrix[ 2 ].xyz ) );\n\n" +
    "		// The thickness is specified in local space.\n" +
    "		return normalize( refractionVector ) * thickness * modelScale;\n\n" +
    "	}\n\n" +
    "	float applyIorToRoughness( const in float roughness, const in float ior ) {\n\n" +
    "		// Scale roughness with IOR so that an IOR of 1.0 results in no microfacet refraction and\n" +
    "		// an IOR of 1.5 results in the default amount of microfacet refraction.\n" +
    "		return roughness * clamp( ior * 2.0 - 2.0, 0.0, 1.0 );\n\n" +
    "	}\n\n" +
    "	vec4 getTransmissionSample( const in vec2 fragCoord, const in float roughness, const in float ior ) {\n\n" +
    "		float lod = log2( transmissionSamplerSize.x ) * applyIorToRoughness( roughness, ior );\n" +
    "		return textureBicubic( transmissionSamplerMap, fragCoord.xy, lod );\n\n" +
    "	}\n\n" +
    "	vec3 volumeAttenuation( const in float transmissionDistance, const in vec3 attenuationColor, const in float attenuationDistance ) {\n\n" +
    "		if ( isinf( attenuationDistance ) ) {\n\n" +
    "			// Attenuation distance is +∞, i.e. the transmitted color is not attenuated at all.\n" +
    "			return vec3( 1.0 );\n\n" +
    "		} else {\n\n" +
    "			// Compute light attenuation using Beer's law.\n" +
    "			vec3 attenuationCoefficient = -log( attenuationColor ) / attenuationDistance;\n" +
    "			vec3 transmittance = exp( - attenuationCoefficient * transmissionDistance ); // Beer's law\n" +
    "			return transmittance;\n\n" +
    "		}\n\n" +
    "	}\n\n" +
    "	vec4 getIBLVolumeRefraction( const in vec3 n, const in vec3 v, const in float roughness, const in vec3 diffuseColor,\n" +
    "		const in vec3 specularColor, const in float specularF90, const in vec3 position, const in mat4 modelMatrix,\n" +
    "		const in mat4 viewMatrix, const in mat4 projMatrix, const in float dispersion, const in float ior, const in float thickness,\n" +
    "		const in vec3 attenuationColor, const in float attenuationDistance ) {\n\n" +
    "		vec4 transmittedLight;\n" +
    "		vec3 transmittance;\n\n" +
    "		#ifdef USE_DISPERSION\n\n" +
    "			float halfSpread = ( ior - 1.0 ) * 0.025 * dispersion;\n" +
    "			vec3 iors = vec3( ior - halfSpread, ior, ior + halfSpread );\n\n" +
    "			for ( int i = 0; i < 3; i ++ ) {\n\n" +
    "				vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, iors[ i ], modelMatrix );\n" +
    "				vec3 refractedRayExit = position + transmissionRay;\n" +
    "		\n" +
    "				// Project refracted vector on the framebuffer, while mapping to normalized device coordinates.\n" +
    "				vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );\n" +
    "				vec2 refractionCoords = ndcPos.xy / ndcPos.w;\n" +
    "				refractionCoords += 1.0;\n" +
    "				refractionCoords /= 2.0;\n" +
    "		\n" +
    "				// Sample framebuffer to get pixel the refracted ray hits.\n" +
    "				vec4 transmissionSample = getTransmissionSample( refractionCoords, roughness, iors[ i ] );\n" +
    "				transmittedLight[ i ] = transmissionSample[ i ];\n" +
    "				transmittedLight.a += transmissionSample.a;\n\n" +
    "				transmittance[ i ] = diffuseColor[ i ] * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance )[ i ];\n\n" +
    "			}\n\n" +
    "			transmittedLight.a /= 3.0;\n" +
    "		\n" +
    "		#else\n" +
    "		\n" +
    "			vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, ior, modelMatrix );\n" +
    "			vec3 refractedRayExit = position + transmissionRay;\n\n" +
    "			// Project refracted vector on the framebuffer, while mapping to normalized device coordinates.\n" +
    "			vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );\n" +
    "			vec2 refractionCoords = ndcPos.xy / ndcPos.w;\n" +
    "			refractionCoords += 1.0;\n" +
    "			refractionCoords /= 2.0;\n\n" +
    "			// Sample framebuffer to get pixel the refracted ray hits.\n" +
    "			transmittedLight = getTransmissionSample( refractionCoords, roughness, ior );\n" +
    "			transmittance = diffuseColor * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance );\n" +
    "		\n" +
    "		#endif\n\n" +
    "		vec3 attenuatedColor = transmittance * transmittedLight.rgb;\n\n" +
    "		// Get the specular component.\n" +
    "		vec3 F = EnvironmentBRDF( n, v, specularColor, specularF90, roughness );\n\n" +
    "		// As less light is transmitted, the opacity should be increased. This simple approximation does a decent job \n" +
    "		// of modulating a CSS background, and has no effect when the buffer is opaque, due to a solid object or clear color.\n" +
    "		float transmittanceFactor = ( transmittance.r + transmittance.g + transmittance.b ) / 3.0;\n\n" +
    "		return vec4( ( 1.0 - F ) * attenuatedColor, 1.0 - ( 1.0 - transmittedLight.a ) * transmittanceFactor );\n\n" +
    "	}\n" +
    "#endif\n"
  );
}