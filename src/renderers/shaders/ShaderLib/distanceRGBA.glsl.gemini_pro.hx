import openfl.display3D.Context3D;
import openfl.display3D.Program3D;

class DistanceShader {

	public static function getVertexShader( context:Context3D ):String {
		return """
			#define DISTANCE

			varying vec3 vWorldPosition;

			#include <common>
			#include <batching_pars_vertex>
			#include <uv_pars_vertex>
			#include <displacementmap_pars_vertex>
			#include <morphtarget_pars_vertex>
			#include <skinning_pars_vertex>
			#include <clipping_planes_pars_vertex>

			void main() {

				#include <uv_vertex>

				#include <batching_vertex>
				#include <skinbase_vertex>

				#include <morphinstance_vertex>

				#ifdef USE_DISPLACEMENTMAP

					#include <beginnormal_vertex>
					#include <morphnormal_vertex>
					#include <skinnormal_vertex>

				#endif

				#include <begin_vertex>
				#include <morphtarget_vertex>
				#include <skinning_vertex>
				#include <displacementmap_vertex>
				#include <project_vertex>
				#include <worldpos_vertex>
				#include <clipping_planes_vertex>

				vWorldPosition = worldPosition.xyz;

			}
		""";
	}

	public static function getFragmentShader( context:Context3D ):String {
		return """
			#define DISTANCE

			uniform vec3 referencePosition;
			uniform float nearDistance;
			uniform float farDistance;
			varying vec3 vWorldPosition;

			#include <common>
			#include <packing>
			#include <uv_pars_fragment>
			#include <map_pars_fragment>
			#include <alphamap_pars_fragment>
			#include <alphatest_pars_fragment>
			#include <alphahash_pars_fragment>
			#include <clipping_planes_pars_fragment>

			void main () {

				vec4 diffuseColor = vec4( 1.0 );
				#include <clipping_planes_fragment>

				#include <map_fragment>
				#include <alphamap_fragment>
				#include <alphatest_fragment>
				#include <alphahash_fragment>

				float dist = length( vWorldPosition - referencePosition );
				dist = ( dist - nearDistance ) / ( farDistance - nearDistance );
				dist = saturate( dist ); // clamp to [ 0, 1 ]

				gl_FragColor = packDepthToRGBA( dist );

			}
		""";
	}

	public static function createProgram( context:Context3D ):Program3D {
		return context.createProgram( getVertexShader( context ), getFragmentShader( context ) );
	}
}


**Explanation:**

1. **Haxe Class:** We define a `DistanceShader` class to hold the shader code.
2. **`getVertexShader` and `getFragmentShader`:** These functions return the vertex and fragment shader code as strings. They are almost identical to the original JavaScript code, but we need to wrap the code in triple quotes () to make it a multiline string.
3. **`createProgram`:** This function creates a `Program3D` object from the vertex and fragment shader code using the `context.createProgram` method.

**Usage:**


// Create a Context3D object
var context:Context3D = new Context3D();

// Create a Program3D object using the DistanceShader class
var program:Program3D = DistanceShader.createProgram( context );

// Use the program for rendering
// ...