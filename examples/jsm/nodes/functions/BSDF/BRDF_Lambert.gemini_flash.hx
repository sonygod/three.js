import ShaderNode from '../../shadernode/ShaderNode';

class BRDF_Lambert {
  public static function evaluate(inputs: { diffuseColor: ShaderNode }): ShaderNode {
    return inputs.diffuseColor.mul(1 / Math.PI); // punctual light
  }
}

export default BRDF_Lambert.evaluate;