import BitangentNode from "./BitangentNode";
import NormalNode from "./NormalNode";
import TangentNode from "./TangentNode";
import ShaderNode from "../shadernode/ShaderNode";
import MathNode from "../math/MathNode";
import PropertyNode from "../core/PropertyNode";
import PositionNode from "./PositionNode";

class TBNViewMatrix extends ShaderNode.Mat3 {
  public function new() {
    super(TangentNode.tangentView, BitangentNode.bitangentView, NormalNode.normalView);
  }
}

var TBNViewMatrix = new TBNViewMatrix();

class ParallaxDirection extends PositionNode.PositionViewDirection {
  public function new() {
    super();
    this.mul(TBNViewMatrix);
    // this.normalize();
  }
}

var parallaxDirection = new ParallaxDirection();

var parallaxUV = function(uv: ShaderNode, scale: ShaderNode) {
  return uv.sub(parallaxDirection.mul(scale));
};

var transformedBentNormalView = (function() {
  // https://google.github.io/filament/Filament.md.html#lighting/imagebasedlights/anisotropy

  var bentNormal = PropertyNode.anisotropyB.cross(PositionNode.positionViewDirection);
  bentNormal = bentNormal.cross(PropertyNode.anisotropyB).normalize();
  bentNormal = MathNode.mix(
    bentNormal,
    NormalNode.transformedNormalView,
    PropertyNode.anisotropy.mul(PropertyNode.roughness.oneMinus()).oneMinus().pow2().pow2()
  ).normalize();

  return bentNormal;
})();

export {
  TBNViewMatrix,
  parallaxDirection,
  parallaxUV,
  transformedBentNormalView
};