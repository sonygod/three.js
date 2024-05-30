import three.js.examples.jsm.nodes.ShaderNode;

class F_Schlick {
    public static function main() {
        var f_Schlick = ShaderNode.tslFn(function(data) {
            var f0 = data.f0;
            var f90 = data.f90;
            var dotVH = data.dotVH;

            // Original approximation by Christophe Schlick '94
            // float fresnel = pow( 1.0 - dotVH, 5.0 );

            // Optimized variant (presented by Epic at SIGGRAPH '13)
            // https://cdn2.unrealengine.com/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
            var fresnel = (dotVH * -5.55473 - 6.98316) * dotVH.exp2();

            return f0 * (1.0 - fresnel) + f90 * fresnel;
        });
    }
}