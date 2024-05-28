var glsl = "
#if defined(USE_ENVMAP)

	#if defined(ENV_WORLDPOS)

		vec3 cameraToFrag;

		if (isOrthographic) {

			cameraToFrag = normalize(vec3(-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]));

		} else {

			cameraToFrag = normalize(vWorldPosition - cameraPosition);

		}

		// Transforming Normal Vectors with the Inverse Transformation
		vec3 worldNormal = inverseTransformDirection(normal, viewMatrix);

		#if defined(ENVMAP_MODE_REFLECTION)

			vec3 reflectVec = reflect(cameraToFrag, worldNormal);

		#else

			vec3 reflectVec = refract(cameraToFrag, worldNormal, refractionRatio);

		#endif

	#else

		vec3 reflectVec = vReflect;

	#endif

	#if defined(ENVMAP_TYPE_CUBE)

		vec4 envColor = textureCube(envMap, envMapRotation * vec3(flipEnvMap * reflectVec.x, reflectVec.yz));

	#else

		vec4 envColor = vec4(0.0);

	#endif

	#if defined(ENVMAP_BLENDING_MULTIPLY)

		outgoingLight = mix(outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity);

	#elif defined(ENVMAP_BLENDING_MIX)

		outgoingLight = mix(outgoingLight, envColor.xyz, specularStrength * reflectivity);

	#elif defined(ENVMAP_BLENDING_ADD)

		outgoingCoefficient += envColor.xyz * specularStrength * reflectivity;

	#endif

#endif
";