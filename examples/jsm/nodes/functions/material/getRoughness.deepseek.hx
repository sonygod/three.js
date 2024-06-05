import getGeometryRoughness from 'three.js.examples.jsm.nodes.functions.material.getGeometryRoughness';
import tslFn from 'three.js.examples.jsm.shadernode.ShaderNode';

class GetRoughness {
    static function getRoughness(inputs:Dynamic):Float {
        var roughness:Float = inputs.roughness;
        var geometryRoughness:Float = getGeometryRoughness();
        var roughnessFactor:Float = Math.max(roughness, 0.0525); // 0.0525 corresponds to the base mip of a 256 cubemap.
        roughnessFactor = roughnessFactor + geometryRoughness;
        roughnessFactor = Math.min(roughnessFactor, 1.0);
        return roughnessFactor;
    }
}

export default GetRoughness;