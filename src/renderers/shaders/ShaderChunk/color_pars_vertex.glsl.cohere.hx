var shaderCode = "#if defined( USE_COLOR_ALPHA )\n\n	varying vec4 vColor;\n\n#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )\n\n	varying vec3 vColor;\n\n#endif";