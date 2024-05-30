package three.js.examples.jsm.nodes.functions.material;

import three.js.examples.jsm.nodes.functions.getGeometryRoughness;

class GetRoughness {
    public static function getRoughness(inputs: { roughness: Float }): Float {
        var geometryRoughness = getGeometryRoughness.getGeometryRoughness();
        var roughnessFactor = Math.max(0.0525, inputs.roughness);
        roughnessFactor += geometryRoughness;
        return Math.min(1.0, roughnessFactor);
    }
}