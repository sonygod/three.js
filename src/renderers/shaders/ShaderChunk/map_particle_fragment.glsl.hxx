import js.Lib;
import haxe.extern.JsMacro;

class Main {
    static public function main() {
        var glsl = /* glsl */`
            #if defined( USE_MAP ) || defined( USE_ALPHAMAP )

                #if defined( USE_POINTS_UV )

                    vec2 uv = vUv;

                #else

                    vec2 uv = ( uvTransform * vec3( gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1 ) ).xy;

                #endif

            #endif

            #ifdef USE_MAP

                diffuseColor *= texture2D( map, uv );

            #endif

            #ifdef USE_ALPHAMAP

                diffuseColor.a *= texture2D( alphaMap, uv ).g;

            #endif
        `;

        js.Lib.eval(glsl);
    }
}

@:build(js.JsMacro.build())
extern class js.JsMacro {
    public static function build() {
        return macro $build($v[0]):js.Syntax.code($v);
    }
}