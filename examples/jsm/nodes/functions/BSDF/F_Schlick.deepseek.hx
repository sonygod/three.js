import three.js.examples.jsm.nodes.functions.BSDF.ShaderNode;

class F_Schlick {
    static function tslFn(f0:Float, f90:Float, dotVH:Float):Float {
        // Original approximation by Christophe Schlick '94
        // float fresnel = pow( 1.0 - dotVH, 5.0 );

        // Optimized variant (presented by Epic at SIGGRAPH '13)
        // https://cdn2.unrealengine.com/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
        var fresnel = dotVH * - 5.55473 - 6.98316 * dotVH;
        fresnel = Math.pow(2, fresnel);

        return f0 * (1 - fresnel) + f90 * fresnel;
    }
}