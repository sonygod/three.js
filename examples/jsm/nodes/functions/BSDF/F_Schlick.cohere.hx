import js.Browser.Math;

class F_Schlick {
    public static function f(f0:Float, f90:Float, dotVH:Float):Float {
        // Original approximation by Christophe Schlick '94
        // float fresnel = pow( 1.0 - dotVH, 5.0 );

        // Optimized variant (presented by Epic at SIGGRAPH '13)
        // https://cdn2.unrealengine.com/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
        var fresnel = Math.exp2(dotVH * (-5.55473) - 6.98316 + dotVH * dotVH);

        return f0 * (1.0 - fresnel) + f90 * fresnel;
    }
}