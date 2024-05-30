import getGeometryRoughness from './getGeometryRoughness.js';
import { tslFn } from '../../shadernode/ShaderNode.js';

@:build(macro function() {
  return tslFn(function(inputs) {
    var roughness = inputs.roughness;
    var geometryRoughness = getGeometryRoughness();
    var roughnessFactor = roughness.max(0.0525); // 0.0525 corresponds to the base mip of a 256 cubemap.
    roughnessFactor = roughnessFactor.add(geometryRoughness);
    roughnessFactor = roughnessFactor.min(1.0);
    return roughnessFactor;
  });
})
class GetRoughness {
  @:build(macro function() return macro $v{inputs}.roughness;)
  public var roughness(default, null);
}

export default GetRoughness;