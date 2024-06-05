import shadernode.ShaderNode;

class BRDF_Lambert {
  public static function eval(inputs: { diffuseColor: ShaderNode.color }): ShaderNode.color {
    return inputs.diffuseColor.mul(1 / Math.PI); // punctual light
  }
}

// Usage:
// var result = BRDF_Lambert.eval({ diffuseColor: someColorNode });