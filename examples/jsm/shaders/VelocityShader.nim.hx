import UniformsLib.{common, displacementmap};
import UniformsUtils.merge;
import Matrix4;

/**
 * Mesh Velocity Shader @bhouston
 */

class VelocityShader {

	static var name:String = 'VelocityShader';

	static var uniforms:Dynamic = merge([
		common,
		displacementmap,
		{
			modelMatrixPrev: { value: new Matrix4() },
			currentProjectionViewMatrix: { value: new Matrix4() },
			previousProjectionViewMatrix: { value: new Matrix4() }
		}
	]);

	static var vertexShader:String = "#define NORMAL\n\n" +
	"#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )\n\n" +
	"	varying vec3 vViewPosition;\n\n" +
	"#endif\n\n" +
	"#include <common>\n" +
	"#include <packing>\n" +
	"#include <uv_pars_vertex>\n" +
	"#include <displacementmap_pars_vertex>\n" +
	"#include <normal_pars_vertex>\n" +
	"#include <morphtarget_pars_vertex>\n" +
	"#include <skinning_pars_vertex>\n" +
	"#include <logdepthbuf_pars_vertex>\n" +
	"#include <clipping_planes_pars_vertex>\n\n" +
	"uniform mat4 previousProjectionViewMatrix;\n" +
	"uniform mat4 currentProjectionViewMatrix;\n\n" +
	"uniform mat4 modelMatrixPrev;\n\n" +
	"varying vec4 clipPositionCurrent;\n" +
	"varying vec4 clipPositionPrevious;\n\n" +
	"void main() {\n\n" +
	"	#include <uv_vertex>\n\n" +
	"	#include <beginnormal_vertex>\n" +
	"	#include <morphnormal_vertex>\n" +
	"	#include <skinbase_vertex>\n" +
	"	#include <skinnormal_vertex>\n" +
	"	#include <defaultnormal_vertex>\n" +
	"	#include <normal_vertex>\n\n" +
	"	#include <begin_vertex>\n" +
	"	#include <morphtarget_vertex>\n" +
	"	#include <displacementmap_vertex>\n" +
	"	#include <morphtarget_vertex>\n" +
	"	#include <skinning_vertex>\n\n" +
	"#ifdef USE_SKINNING\n\n" +
	"	vec4 mvPosition = modelViewMatrix * skinned;\n" +
	"	clipPositionCurrent  = currentProjectionViewMatrix * modelMatrix * skinned;\n" +
	"	clipPositionPrevious = previousProjectionViewMatrix * modelMatrixPrev * skinned;\n\n" +
	"#else\n\n" +
	"	vec4 mvPosition = modelViewMatrix * vec4( transformed, 1.0 );\n" +
	"	clipPositionCurrent  = currentProjectionViewMatrix * modelMatrix * vec4( transformed, 1.0 );\n" +
	"	clipPositionPrevious = previousProjectionViewMatrix * modelMatrixPrev * vec4( transformed, 1.0 );\n\n" +
	"#endif\n\n" +
	"	gl_Position = projectionMatrix * mvPosition;\n\n" +
	"	#include <logdepthbuf_vertex>\n" +
	"	#include <clipping_planes_vertex>\n" +
	"}";

	static var fragmentShader:String = "#define NORMAL\n\n" +
	"uniform float opacity;\n\n" +
	"#include <packing>\n" +
	"#include <uv_pars_fragment>\n" +
	"#include <map_pars_fragment>\n" +
	"#include <alphamap_pars_fragment>\n" +
	"#include <alphatest_pars_fragment>\n" +
	"#include <logdepthbuf_pars_fragment>\n" +
	"#include <clipping_planes_pars_fragment>\n\n" +
	"varying vec4 clipPositionCurrent;\n" +
	"varying vec4 clipPositionPrevious;\n\n" +
	"void main() {\n\n" +
	"	vec4 diffuseColor = vec4( 1.0 );\n" +
	"	diffuseColor.a = opacity;\n\n" +
	"	#include <map_fragment>\n" +
	"	#include <alphamap_fragment>\n" +
	"	#include <alphatest_fragment>\n\n" +
	"	vec2 ndcPositionCurrent  = clipPositionCurrent.xy/clipPositionCurrent.w;\n" +
	"	vec2 ndcPositionPrevious = clipPositionPrevious.xy/clipPositionPrevious.w;\n" +
	"	vec2 vel = ( ndcPositionCurrent - ndcPositionPrevious ) * 0.5;\n" +
	"	vel = vel * 0.5 + 0.5;\n" +
	"	vec2 v1 = packDepthToRG(vel.x);\n" +
	"	vec2 v2 = packDepthToRG(vel.y);\n" +
	"	gl_FragColor = vec4(v1.x, v1.y, v2.x, v2.y);\n\n" +
	"	#include <logdepthbuf_fragment>\n" +
	"}";
}