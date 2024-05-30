package three.js.examples.jvm.nodes.accessors;

import three.js.examples.jvm.nodes.BitangentNode;
import three.js.examples.jvm.nodes.NormalNode;
import three.js.examples.jvm.nodes.TangentNode;
import three.js.examples.jvm.shadernode.ShaderNode;
import three.js.examples.jvm.math.MathNode;
import three.js.examples.jvm.core.PropertyNode;
import three.js.examples.jvm.nodes.PositionNode;

class AccessorsUtils {
  static public var TBNViewMatrix = new Mat3(
    TangentNode.tangentView,
    BitangentNode.bitangentView,
    NormalNode.normalView
  );

  static public var parallaxDirection = PositionNode.positionViewDirection.mul(TBNViewMatrix); ///*.normalize()*/;
  static public function parallaxUV(uv:Vector2, scale:Float) {
    return uv.sub(parallaxDirection.mul(scale));
  }

  static public var transformedBentNormalView = (() -> {
    var bentNormal = PropertyNode.anisotropyB.cross(PositionNode.positionViewDirection);
    bentNormal = bentNormal.cross(PropertyNode.anisotropyB).normalize();
    bentNormal = MathNode.mix(
      bentNormal,
      NormalNode.transformedNormalView,
      PropertyNode.anisotropy.mul(PropertyNode.roughness.oneMinus()).oneMinus().pow(2).pow(2)
    ).normalize();
    return bentNormal;
  })();
}