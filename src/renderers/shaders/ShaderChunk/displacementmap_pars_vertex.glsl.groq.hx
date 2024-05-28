package three.shaderlib;

import haxe.macro.Expr;

class DisplacementMapParsVertex {
    public static var shader: String = {
        #if USE_DISPLACEMENTMAP
        "
            uniform sampler2D displacementMap;
            uniform float displacementScale;
            uniform float displacementBias;
        "
        #end
    }
}