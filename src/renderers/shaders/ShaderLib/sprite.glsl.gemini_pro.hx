import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ComplexType;
import haxe.macro.ComplexType.Enum;
import haxe.macro.ComplexType.Record;
import haxe.macro.ComplexType.Abstract;
import haxe.macro.ComplexType.Interface;
import haxe.macro.ComplexType.Field;
import haxe.macro.ComplexType.Parameter;
import haxe.macro.ComplexType.Function;
import haxe.macro.ComplexType.TypeExpr;
import haxe.macro.Expr.TConst;
import haxe.macro.Expr.TExpr;
import haxe.macro.Expr.TField;
import haxe.macro.Expr.TBlock;
import haxe.macro.Expr.TCall;
import haxe.macro.Expr.TIdent;
import haxe.macro.Expr.TBinop;
import haxe.macro.Expr.TUnop;
import haxe.macro.Expr.TString;
import haxe.macro.Expr.TFloat;
import haxe.macro.Expr.TInt;
import haxe.macro.Expr.TArray;
import haxe.macro.Expr.TObject;
import haxe.macro.Expr.TIf;
import haxe.macro.Expr.TWhile;
import haxe.macro.Expr.TFor;
import haxe.macro.Expr.TBreak;
import haxe.macro.Expr.TContinue;
import haxe.macro.Expr.TReturn;
import haxe.macro.Expr.TNew;
import haxe.macro.Expr.TThis;
import haxe.macro.Expr.TSuper;
import haxe.macro.Expr.TFunction;
import haxe.macro.Expr.TClass;
import haxe.macro.Expr.TEnum;
import haxe.macro.Expr.TType;
import haxe.macro.Expr.TPackage;
import haxe.macro.Expr.TImport;
import haxe.macro.Expr.TMeta;
import haxe.macro.Expr.TUsing;
import haxe.macro.Expr.TVar;
import haxe.macro.Expr.TPath;
import haxe.macro.Expr.TAnon;
import haxe.macro.Expr.TInterp;
import haxe.macro.Expr.TInlined;
import haxe.macro.Expr.TMacro;
import haxe.macro.Expr.TAssign;

class GlslConverter {

    static function convert(code:String):String {
        var lines = code.split("\n");
        var result = new Array<String>();

        var inString = false;
        var stringQuote = "";

        for (line in lines) {
            var currentLine = "";
            for (i in 0...line.length) {
                var char = line.charAt(i);
                if (inString) {
                    if (char == stringQuote) {
                        inString = false;
                        stringQuote = "";
                    }
                    currentLine += char;
                } else {
                    if (char == '"' || char == "'") {
                        inString = true;
                        stringQuote = char;
                    }
                    currentLine += char;
                }
            }
            result.push(currentLine);
        }

        var output = "";
        for (i in 0...result.length) {
            var line = result[i];
            if (line.startsWith("export const ")) {
                var name = line.split(" ")[2].split("=")[0];
                var content = line.split("=")[1].split(";")[0].trim();
                if (content.startsWith("/* glsl */")) {
                    var glslContent = content.substring(9, content.length - 1).trim();
                    output += "static inline function " + name + "():String { return " + glslContent + "; }";
                }
            }
        }

        return output;
    }
}

class Main {
    static function main() {
        var code = """
export const vertex = /* glsl */`
uniform float rotation;
uniform vec2 center;

#include <common>
#include <uv_pars_vertex>
#include <fog_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>

void main() {

	#include <uv_vertex>

	vec4 mvPosition = modelViewMatrix * vec4( 0.0, 0.0, 0.0, 1.0 );

	vec2 scale;
	scale.x = length( vec3( modelMatrix[ 0 ].x, modelMatrix[ 0 ].y, modelMatrix[ 0 ].z ) );
	scale.y = length( vec3( modelMatrix[ 1 ].x, modelMatrix[ 1 ].y, modelMatrix[ 1 ].z ) );

	#ifndef USE_SIZEATTENUATION

		bool isPerspective = isPerspectiveMatrix( projectionMatrix );

		if ( isPerspective ) scale *= - mvPosition.z;

	#endif

	vec2 alignedPosition = ( position.xy - ( center - vec2( 0.5 ) ) ) * scale;

	vec2 rotatedPosition;
	rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;
	rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;

	mvPosition.xy += rotatedPosition;

	gl_Position = projectionMatrix * mvPosition;

	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>

}
`;

export const fragment = /* glsl */`
uniform vec3 diffuse;
uniform float opacity;

#include <common>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
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
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>

	outgoingLight = diffuseColor.rgb;

	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>

}
`;
        """
        trace(GlslConverter.convert(code));
    }
}