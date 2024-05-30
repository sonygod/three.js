package three js.examples.jm.nodes.accessors;

import three.js.core.AttributeNode;
import three.js.core.PropertyNode;
import three.js.core.VaryingNode;
import three.js.nodes.CameraNode;
import three.js.nodes.ModelNode;
import three.js.shaderNode.ShaderNode;

class NormalNode {
    public static var normalGeometry:AttributeNode = AttributeNode.create('normal', 'vec3', new Vec3(0, 1, 0));
    public static var normalLocal:VaryingNode = VaryingNode.create(normalGeometry, 'normalLocal');
    public static var normalView:VaryingNode = VaryingNode.create(ModelNode.modelNormalMatrix.multiply(normalLocal), 'normalView').normalize();
    public static var normalWorld:VaryingNode = VaryingNode.create(normalView.transformDirection(CameraNode.cameraViewMatrix), 'normalWorld').normalize();
    public static var transformedNormalView:PropertyNode = PropertyNode.create('vec3', 'transformedNormalView');
    public static var transformedNormalWorld:VaryingNode = normalView.transformDirection(CameraNode.cameraViewMatrix).normalize();
    public static var transformedClearcoatNormalView:PropertyNode = PropertyNode.create('vec3', 'transformedClearcoatNormalView');
}