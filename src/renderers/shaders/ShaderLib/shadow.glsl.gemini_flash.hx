import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Field;
import haxe.macro.Type;
import haxe.macro.ComplexType;
import haxe.macro.Macro;
import haxe.macro.Tools;

class Glsl extends Macro {
  static function process(field:Field, context:Context):Expr {
    var t = field.type;
    if (t.is(ComplexType.Complex) && t.as(ComplexType.Complex).kind == "String") {
      var val = t.as(ComplexType.Complex).expr.as(Expr.Const).getConst();
      if (val is String) {
        var code = val.split("\n").map(function(line) {
          if (line.trim().startsWith("#include")) {
            var directive = line.trim();
            var includeFile = directive.split(" ").pop().replace("\"", "").replace("<", "").replace(">", "");
            if (includeFile.trim() != "") {
              var includePath = context.currentPath.split("/").slice(0, -1).join("/") + "/" + includeFile;
              var includeCode = StringTools.trim(Tools.getFile(includePath));
              return includeCode.split("\n").map(function(line) {
                return "\t" + line;
              }).join("\n");
            }
          }
          return "\t" + line;
        }).join("\n");
        return Expr.Const(code);
      }
    }
    return Expr.Error("Invalid Glsl macro usage");
  }
}

class Main {
  static function main() {
    var vertex = @:glsl`
#include <common>
#include <batching_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <shadowmap_pars_vertex>

void main() {

	#include <batching_vertex>

	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>

	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>

	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>

}
`;

    var fragment = @:glsl`
uniform vec3 color;
uniform float opacity;

#include <common>
#include <packing>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <logdepthbuf_pars_fragment>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>

void main() {

	#include <logdepthbuf_fragment>

	gl_FragColor = vec4( color, opacity * ( 1.0 - getShadowMask() ) );

	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>

}
`;

    trace(vertex);
    trace(fragment);
  }
}