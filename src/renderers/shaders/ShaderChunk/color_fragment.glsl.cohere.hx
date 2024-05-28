var shaderCode = #if defined( USE_COLOR_ALPHA )

	diffuseColor *= vColor;

#elif defined( USE_COLOR )

	differseColor.rgb *= vColor;

#endif;