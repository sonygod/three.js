package three.js.examples.jsm.nodes.accessors;

import three.core.AttributeNode;
import three.core.VaryingNode;
import three.core.PropertyNode;
import three.nodes.CameraNode;
import three.nodes.ModelNode;
import three.shadernode.ShaderNode;

class NormalNode {
    public static var normalGeometry:AttributeNode = AttributeNode.create("normal", "vec3", new Vec3(0, 1, 0));
    public static var normalLocal:VaryingNode = VaryingNode.createFromAttribute(normalGeometry, "normalLocal");
    public static var normalView:VaryingNode = VaryingNode.create(ModelNode.modelNormalMatrix.multiply(normalLocal), "normalView").normalize();
    public static var normalWorld:VaryingNode = VaryingNode.create(normalView.transformDirection(CameraNode.cameraViewMatrix), "normalWorld").normalize();
    public static var transformedNormalView:PropertyNode = PropertyNode.create("vec3", "transformedNormalView");
    public static var transformedNormalWorld:PropertyNode = transformedNormalView.transformDirection(CameraNode.cameraViewMatrix).normalize();
    public static var transformedClearcoatNormalView:PropertyNode = PropertyNode.create("vec3", "transformedClearcoatNormalView");
}