package three.src.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("fog_fragment.glsl"))
class FogFragment {

  static var fragment = /* glsl */`
#ifdef USE_FOG

	#ifdef FOG_EXP2

		float fogFactor = 1.0 - exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );

	#else

		float fogFactor = smoothstep( fogNear, fogFar, vFogDepth );

	#endif

	gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );

#endif
`;

}