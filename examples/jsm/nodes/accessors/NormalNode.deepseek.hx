import AttributeNode;
import VaryingNode;
import PropertyNode;
import CameraNode;
import ModelNode;
import ShaderNode;

class NormalNode {
    static var normalGeometry:AttributeNode = AttributeNode.attribute('normal', 'vec3', ShaderNode.vec3(0, 1, 0));
    static var normalLocal:VaryingNode = VaryingNode.varying(normalGeometry).toVar('normalLocal');
    static var normalView:VaryingNode = VaryingNode.varying(ModelNode.modelNormalMatrix.mul(normalLocal), 'normalView').normalize();
    static var normalWorld:VaryingNode = VaryingNode.varying(normalView.transformDirection(CameraNode.cameraViewMatrix), 'normalWorld').normalize();
    static var transformedNormalView:PropertyNode = PropertyNode.property('vec3', 'transformedNormalView');
    static var transformedNormalWorld:PropertyNode = transformedNormalView.transformDirection(CameraNode.cameraViewMatrix).normalize();
    static var transformedClearcoatNormalView:PropertyNode = PropertyNode.property('vec3', 'transformedClearcoatNormalView');
}