import js.Browser.Float32Array;
import js.Browser.Math;

import js.webgl.Math as GLMath;

import js.WebGL.RenderingContext2D.prototype.*;

class D_GGX_Anisotropic {
    public static inline function get(alphaT: Float, alphaB: Float, dotNH: Float, dotTH: Float, dotBH: Float): Float {
        var a2 = alphaT * alphaB;
        var v = GLMath.vec3(alphaB * dotTH, alphaT * dotBH, a2 * dotNH);
        var v2 = GLMath.dot(v, v);
        var w2 = a2 / v2;
        return RECIPROCAL_PI * a2 * (w2 * w2);
    }
}

const RECIPROCAL_PI = 1.0 / Math.PI;

class ShaderNode {
    public var D_GGX_Anisotropic: D_GGX_Anisotropic;
}

class Filament {
    public static var MaterialSystem: {
        AnisotropicModel: {
            AnisotropicSpecularBRDF: ShaderNode;
        }
    }
}