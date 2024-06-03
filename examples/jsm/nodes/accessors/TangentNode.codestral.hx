import jsm.nodes.core.AttributeNode;
import jsm.nodes.core.VaryingNode;
import jsm.nodes.accessors.CameraNode;
import jsm.nodes.accessors.ModelNode;
import jsm.shadernode.ShaderNode;

@:build(no)
class TangentNode {
  static var tangentGeometry: AttributeNode;
  static var tangentLocal: VaryingNode;
  static var tangentView: VaryingNode;
  static var tangentWorld: VaryingNode;
  static var transformedTangentView: VaryingNode;
  static var transformedTangentWorld: VaryingNode;

  static function init() {
    tangentGeometry = ShaderNode.tslFn((stack, builder) => {
      if (!builder.geometry.hasAttribute('tangent')) {
        builder.geometry.computeTangents();
      }
      return AttributeNode.attribute('tangent', 'vec4');
    })();

    tangentLocal = VaryingNode.varying(tangentGeometry.xyz, 'tangentLocal');
    tangentView = VaryingNode.varying(ModelNode.modelViewMatrix.mul(ShaderNode.vec4(tangentLocal, 0)).xyz, 'tangentView').normalize();
    tangentWorld = VaryingNode.varying(tangentView.transformDirection(CameraNode.cameraViewMatrix), 'tangentWorld').normalize();
    transformedTangentView = tangentView.toVar('transformedTangentView');
    transformedTangentWorld = transformedTangentView.transformDirection(CameraNode.cameraViewMatrix).normalize();
  }
}