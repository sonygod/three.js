import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ComplexType;
import haxe.macro.Const;
import haxe.macro.Code;
import haxe.macro.Macro;
import haxe.macro.Expr.Ident;
import haxe.macro.Expr.String;

class GLSL {

	static public function vertex(ctx:Context):Expr {
		return stringToExpr(ctx, """
			#include <common>
			#include <batching_pars_vertex>
			#include <uv_pars_vertex>
			#include <envmap_pars_vertex>
			#include <color_pars_vertex>
			#include <fog_pars_vertex>
			#include <morphtarget_pars_vertex>
			#include <skinning_pars_vertex>
			#include <logdepthbuf_pars_vertex>
			#include <clipping_planes_pars_vertex>

			void main() {

				#include <uv_vertex>
				#include <color_vertex>
				#include <morphinstance_vertex>
				#include <morphcolor_vertex>
				#include <batching_vertex>

				#if defined ( USE_ENVMAP ) || defined ( USE_SKINNING )

					#include <beginnormal_vertex>
					#include <morphnormal_vertex>
					#include <skinbase_vertex>
					#include <skinnormal_vertex>
					#include <defaultnormal_vertex>

				#endif

				#include <begin_vertex>
				#include <morphtarget_vertex>
				#include <skinning_vertex>
				#include <project_vertex>
				#include <logdepthbuf_vertex>
				#include <clipping_planes_vertex>

				#include <worldpos_vertex>
				#include <envmap_vertex>
				#include <fog_vertex>

			}
		""");
	}

	static public function fragment(ctx:Context):Expr {
		return stringToExpr(ctx, """
			uniform vec3 diffuse;
			uniform float opacity;

			#ifndef FLAT_SHADED

				varying vec3 vNormal;

			#endif

			#include <common>
			#include <dithering_pars_fragment>
			#include <color_pars_fragment>
			#include <uv_pars_fragment>
			#include <map_pars_fragment>
			#include <alphamap_pars_fragment>
			#include <alphatest_pars_fragment>
			#include <alphahash_pars_fragment>
			#include <aomap_pars_fragment>
			#include <lightmap_pars_fragment>
			#include <envmap_common_pars_fragment>
			#include <envmap_pars_fragment>
			#include <fog_pars_fragment>
			#include <specularmap_pars_fragment>
			#include <logdepthbuf_pars_fragment>
			#include <clipping_planes_pars_fragment>

			void main() {

				vec4 diffuseColor = vec4( diffuse, opacity );
				#include <clipping_planes_fragment>

				#include <logdepthbuf_fragment>
				#include <map_fragment>
				#include <color_fragment>
				#include <alphamap_fragment>
				#include <alphatest_fragment>
				#include <alphahash_fragment>
				#include <specularmap_fragment>

				ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );

				// accumulation (baked indirect lighting only)
				#ifdef USE_LIGHTMAP

					vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
					reflectedLight.indirectDiffuse += lightMapTexel.rgb * lightMapIntensity * RECIPROCAL_PI;

				#else

					reflectedLight.indirectDiffuse += vec3( 1.0 );

				#endif

				// modulation
				#include <aomap_fragment>

				reflectedLight.indirectDiffuse *= diffuseColor.rgb;

				vec3 outgoingLight = reflectedLight.indirectDiffuse;

				#include <envmap_fragment>

				#include <opaque_fragment>
				#include <tonemapping_fragment>
				#include <colorspace_fragment>
				#include <fog_fragment>
				#include <premultiplied_alpha_fragment>
				#include <dithering_fragment>

			}
		""");
	}

	static function stringToExpr(ctx:Context, code:String):Expr {
		var str = new String(code);
		return macro.Expr.Function({
			name: "getShader",
			args: [],
			ret: {
				t: {
					t: ComplexType.t(Type.get({
						name: "String",
						params: []
					}), []),
					n: ""
				}
			},
			body: macro.Code.Block([
				macro.Code.Return(str)
			])
		});
	}

}

class Main {

	static function main() {
		trace(GLSL.vertex(null));
		trace(GLSL.fragment(null));
	}

}