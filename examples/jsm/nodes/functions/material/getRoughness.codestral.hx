import GetGeometryRoughness from './getGeometryRoughness';
import ShaderNode from '../../shadernode/ShaderNode';

class GetRoughness {
    public static function call(inputs: Dynamic): Float {
        var roughness: Float = inputs.roughness;
        var geometryRoughness: Float = GetGeometryRoughness.call();

        var roughnessFactor: Float = Math.max(roughness, 0.0525); // 0.0525 corresponds to the base mip of a 256 cubemap.
        roughnessFactor = roughnessFactor + geometryRoughness;
        roughnessFactor = Math.min(roughnessFactor, 1.0);

        return roughnessFactor;
    }
}

var getRoughness: (Dynamic -> Float) = ShaderNode.tslFn(GetRoughness.call);

export default getRoughness;