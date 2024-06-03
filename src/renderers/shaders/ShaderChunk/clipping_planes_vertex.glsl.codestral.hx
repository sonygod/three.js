// Haxe code
package renderers.shaders.ShaderChunk;

class ClippingPlanesVertex {
    static function generate(): String {
        #if NUM_CLIPPING_PLANES > 0
            return "vClipPosition = - mvPosition.xyz;";
        #else
            return "";
        #end
    }
}