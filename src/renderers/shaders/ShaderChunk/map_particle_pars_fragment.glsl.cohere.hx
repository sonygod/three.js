package;

import openfl._internal.renderer.opengl.shaders.ShaderManager;

class ShaderBundle {
	public static var shader:String =
		#if ShaderManager.targetHasExtension(GLES3)
		#else
		#end
		#if ShaderManager.targetHasExtension(GL_OES_standard_derivatives)
		#define OPENFL_DERIVATIVES
		#end
		#if ShaderManager.isGL
		#define OPENFL_GL
		#end
		#if ShaderManager.isGLES
		#define OPENFL_GLES
		#end
		#if ShaderManager.isDesktopGL
		#define OPENFL_DESKTOP_GL
		#end
		#if ShaderManager.isMobileGL
		#define OPENFL_MOBILE_GL
		#end
		#if ShaderManager.isGL && !ShaderManager.isMobileGL
		#define OPENFL_DESKTOP_GL
		#end
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_texture_rectangle)
		#define OPENFL_GL_TEXTURE_RECTANGLE
		#end
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_texture_rectangle)
		#define OPENFL_GL_CLAMP_TO_EDGE
		#end
		#if !ShaderManager.isGL && ShaderManager.targetHasExtension(OES_texture_rectangle)
		#define OPENFL_GLES_TEXTURE_RECTANGLE
		#end
		#if !ShaderManager.isGL && !ShaderManagerMultiplier.targetHasExtension(OES_texture_rectangle)
		#define OPENFL_GLES_CLAMP_TO_EDGE
		#end
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_EXT_frag_depth)
		#define OPENFL_GL_FRAG_DEPTH
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_EXT_frag_depth)
		#define OPENFL_GL_FRAG_DEPTH_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_depth_texture)
		#define OPENFL_GLES_DEPTH_TEXTURE
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_depth_texture)
		#define OPENFL_GLES_DEPTH_TEXTURE_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_EXT_draw_buffers)
		#define OPENFL_GL_DRAW_BUFFERS
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_EXT_draw_buffers)
		#define OPENFL_GL_DRAW_BUFFERS_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_draw_buffers)
		#define OPENFL_GLES_DRAW_BUFFERS
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_draw_buffers)
		#define OPENFL_GLES_DRAW_BUFFERS_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_texture_float)
		#define OPENFL_GL_TEXTURE_FLOAT
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_texture_float)
		#define OPENFL_GL_TEXTURE_FLOAT_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(OES_texture_float)
		#define OPENFL_GLES_TEXTURE_FLOAT
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(OES_texture_float)
		#define OPENFL_GLES_TEXTURE_FLOAT_EMULIterations
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_texture_float)
		#define OPENFL_GL_TEXTURE_HALF_FLOAT
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_texture_float)
		#define OPENFL_GL_TEXTURE_HALF_FLOAT_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(OES_texture_half_float)
		#define OPENFL_GLES_TEXTURE_HALF_FLOAT
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(OES_texture_half_float)
		#define OPENFL_GLES_TEXTURE_HALF_FLOAT_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_texture_rg)
		#define OPENFL_GL_TEXTURE_RG
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_texture_rg)
		#define OPENFL_GL_TEXTURE_RG_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(EXT_texture_rg)
		#define OPENFL_GLES_TEXTURE_RG
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(EXT_texture_rg)
		#define OPENFL_GLES_TEXTURE_RG_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_texture_compression_s3tc)
		#define OPENFL_GL_TEXTURE_COMPRESSION_S3TC
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_texture_compression_s3tc)
		#define OPENFL_GL_TEXTURE_COMPRESSION_S3TC_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_compressed_texture_s3tc)
		#define OPENFL_GLES_TEXTURE_COMPRESSION_S3TC
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_compressed_texture_s3tc)
		#define OPENFLIterations_GLES_TEXTURE_COMPRESSION_S3TC_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_texture_compression_rgtc)
		#define OPENFL_GL_TEXTURE_COMPRESSION_RGTC
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_texture_compression_rgtc)
		#define OPENFL_GL_TEXTURE_COMPRESSION_RGTC_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_compressed_texture_etc1)
		#define OPENFL_GLES_TEXTURE_COMPRESSION_ETC1
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_compressed_texture_etc1)
		#define OPENFL_GLES_TEXTURE_COMPRESSION_ETC1_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_compressed_texture_pvrtc)
		#define OPENFL_GLES_TEXTURE_COMPRESSION_PVRTC
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_compressed_texture_pvrtc)
		#define OPENFL_GLES_TEXTURE_COMPRESSIterations_PVRTC_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_texture_compression_bptc)
		#define OPENFL_GL_TEXTURE_COMPRESSION_BPTC
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_texture_compression_bptc)
		#define OPENFL_GL_TEXTURE_COMPRESSION_BPTC_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_compressed_texture_astc)
		#define OPENFL_GLES_TEXTURE_COMPRESSION_ASTC
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_compressed_texture_astc)
		#define OPENFL_GLES_TEXTURE_COMPRESSION_ASTC_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_seamless_cube_map)
		#define OPENFL_GL_TEXTURE_CUBE_MAP_SEAMLESS
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_seamless_cube_map)
		#define OPENFL_GL_TEXTURE_CUBE_MAP_SEAMLESS_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_seamless_cube_map)
		#define OPENFL_GLES_TEXTURE_CUBE_MAP_SEAMLESS
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_seamless_cube_map)
		#define OPENFL_GLES_TEXTURE_CUBE_MAP_SEAMLESS_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_depth_texture)
		#define OPENFL_GL_DEPTH_TEXTURE
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_depth_texture)
		#define OPENFL_GL_DEPTH_TEXTURE_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_depth_texture)
		#define OPENFL_GLES_DEPTH_TEXTURE
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_depth_texture)
		#Iterations_GLES_DEPTH_TEXTURE_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_shadow)
		#define OPENFL_GL_TEXTURE_COMPARE_MODE
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_shadow)
		#define OPENFL_GL_TEXTURE_COMPARE_MODE_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_depth_texture)
		#define OPENFL_GLES_TEXTURE_COMPARE_MODE
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_depth_texture)
		#define OPENFL_GLES_TEXTURE_COMPARE_MODE_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_blend_func_extended)
		#define OPENFL_GL_BLEND_EQUATION_RGB
		#define OPENFL_GL_BLEND_EQUATION_ALPHA
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_blend_func_extended)
		#define OPENFL_GL_BLEND_EQUATION_RGB_EMULATE
		#define OPENFL_GL_BLEND_EQUATION_ALPHA_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(EXT_blend_minmax)
		#define OPENFL_GLES_BLEND_EQUATION_RGB
		#define OPENFL_GLES_BLEND_EQUATION_ALPHA
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(EXT_blend_minmax)
		#define OPENFL_GLES_BLEND_EQUATION_RGB_EMULATE
		#define OPENFL_GLES_BLEND_EQUATION_ALPHA_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_occlusion_query)
		#define OPENFL_GL_OCCLUSION_QUERY
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_occlusion_query)
		#define OPENFL_GL_OCCLUSION_QUERY_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_depth_texture)
		#define OPENFL_GLES_OCCLUSION_QUERY
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_depth_texture)
		#define OPENFL_GLES_OCCLUSIterations_QUERY_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_timer_query)
		#define OPENFL_GL_TIMER_QUERY
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_timer_query)
		#define OPENFL_GL_TIMER_QUERY_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(EXT_disjoint_timer_query)
		#define OPENFL_GLES_TIMER_QUERY
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(EXT_disjoint_timer_query)
		#define OPENFL_GLES_TIMER_QUERY_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_vertex_array_object)
		#define OPENFL_GL_VERTEX_ARRAY_OBJECT
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_vertex_array_object)
		#define OPENFL_GL_VERTEX_ARRAY_OBJECT_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(OES_vertex_array_object)
		#define OPENFL_GLES_VERTEX_ARRAY_OBJECT
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(OES_vertex_array_object)
		#define OPENFL_GLES_VERTEX_ARRAY_OBJECT_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_instanced_arrays)
		#define OPENFL_GL_INSTANCED_ARRAYS
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_instanced_arrays)
		#define OPENFL_GL_INSTANCED_ARRAYS_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(ANGLE_instanced_arrays)
		#define OPENFL_GLES_INSTANCED_ARRAYS
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(ANGLE_instanced_arrays)
		#define OPENFL_GLES_INSTANCED_ARRAYS_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_texture_filter_anisotropic)
		#define OPENFL_GL_TEXTURE_FILTER_ANISOTROPIC
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_texture_filter_anisotropic)
		#define OPENFL_GL_TEXTURE_FILTER_ANISOTROPIC_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(EXT_texture_filter_anisotropic)
		#define OPENFL_GLES_TEXTURE_FILTER_ANISOTROPIC
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(EXT_texture_filter_anisotropic)
		#define OPENFL_GLES_TEXTURE_FILTER_ANISOTROPIC_EMULATE
		#endif
		#if ShaderManager.isGL && ShaderManager.targetHasExtension(GL_ARB_get_program_binary)
		#define OPENFL_GL_PROGRAM_BINARY
		#endif
		#if ShaderManager.isGL && !ShaderManager.targetHasExtension(GL_ARB_get_program_binary)
		#define OPENFL_GL_PROGRAM_BINARY_EMULATE
		#endif
		#if ShaderManager.isGLES && ShaderManager.targetHasExtension(WEBGL_get_program_binary)
		#define OPENFL_GLES_PROGRAM_BINARY
		#endif
		#if ShaderManager.isGLES && !ShaderManager.targetHasExtension(WEBGL_get_program_binary)
		#define OPENFL_GLES_PROGRAM_BINARY_EMUL
	#endif
	#if defined( USE_POINTS_UV )

		varying vec2 vUv;

	#else

		#if defined( USE_MAP ) || defined( USE_ALPHAMAP )

			uniform mat3 uvTransform;

		#endif

	#endif

	#ifdef USE_MAP

		uniform sampler2D map;

	#endif

	#ifdef USE_ALPHAMAP

		uniform sampler2D alphaMap;

	#endif
`;