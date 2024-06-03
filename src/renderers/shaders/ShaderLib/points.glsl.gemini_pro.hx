import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ComplexType;
import haxe.macro.Field;
import haxe.macro.Function;
import haxe.macro.Constant;
import haxe.macro.Access;
import haxe.macro.FieldAccess;
import haxe.macro.ExprOps;
import haxe.macro.Macro;
import haxe.macro.StringInterpolation;
import haxe.macro.Tools;

class GlslMacro extends Macro {
  public static function get(context:Context):Expr {
    var code = context.currentFunction().body.expr;
    var args:Array<Expr> = [];
    args.push(code);
    return Expr.call(Expr.field(Expr.ident("glsl"), "get"), args);
  }
}

class Glsl {
  public static function get(code:Expr):Expr {
    if (code.expr is StringInterpolation) {
      var parts = (code.expr as StringInterpolation).parts;
      var interpolation = "";
      for (i in 0...parts.length) {
        interpolation += parts[i];
        if (i < parts.length - 1) {
          interpolation += ((parts[i + 1].expr as Constant).value).toString();
        }
      }
      return Expr.string(interpolation);
    }
    return code;
  }
}

export class Points {
  public static function vertex():String {
    return glsl`
uniform float size;
uniform float scale;

#include <common>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>

#ifdef USE_POINTS_UV

	varying vec2 vUv;
	uniform mat3 uvTransform;

#endif

void main() {

	#ifdef USE_POINTS_UV

		vUv = ( uvTransform * vec3( uv, 1 ) ).xy;

	#endif

	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>

	gl_PointSize = size;

	#ifdef USE_SIZEATTENUATION

		bool isPerspective = isPerspectiveMatrix( projectionMatrix );

		if ( isPerspective ) gl_PointSize *= ( scale / - mvPosition.z );

	#endif

	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <fog_vertex>

}
`;
  }

  public static function fragment():String {
    return glsl`
uniform vec3 diffuse;
uniform float opacity;

#include <common>
#include <color_pars_fragment>
#include <map_particle_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>

void main() {

	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>

	vec3 outgoingLight = vec3( 0.0 );

	#include <logdepthbuf_fragment>
	#include <map_particle_fragment>
	#include <color_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>

	outgoingLight = diffuseColor.rgb;

	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>

}
`;
  }
}