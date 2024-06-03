import jsm.nodes.core.AttributeNode;
import jsm.nodes.core.VaryingNode;
import jsm.nodes.core.PropertyNode;
import jsm.nodes.accessors.CameraNode;
import jsm.nodes.accessors.ModelNode;
import jsm.shadernode.ShaderNode;

var normalGeometry:VaryingNode<Float> = AttributeNode.attribute("normal", "vec3", ShaderNode.vec3(0, 1, 0));
var normalLocal:VaryingNode<Float> = VaryingNode.varying(normalGeometry).toVar("normalLocal");
var normalView:VaryingNode<Float> = VaryingNode.varying(ModelNode.modelNormalMatrix.mul(normalLocal), "normalView").normalize();
var normalWorld:VaryingNode<Float> = VaryingNode.varying(normalView.transformDirection(CameraNode.cameraViewMatrix), "normalWorld").normalize();
var transformedNormalView:PropertyNode<Float> = PropertyNode.property("vec3", "transformedNormalView");
var transformedNormalWorld:VaryingNode<Float> = transformedNormalView.transformDirection(CameraNode.cameraViewMatrix).normalize();
var transformedClearcoatNormalView:PropertyNode<Float> = PropertyNode.property("vec3", "transformedClearcoatNormalView");