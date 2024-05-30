import three.js.examples.jsm.nodes.core.AttributeNode;
import three.js.examples.jsm.nodes.core.VaryingNode;
import three.js.examples.jsm.nodes.accessors.CameraNode;
import three.js.examples.jsm.nodes.accessors.ModelNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class TangentNode {
    static var tangentGeometry:ShaderNode = ShaderNode.tslFn((stack, builder) -> {
        if (builder.geometry.hasAttribute('tangent') == false) {
            builder.geometry.computeTangents();
        }
        return AttributeNode.attribute('tangent', 'vec4');
    });

    static var tangentLocal:VaryingNode = VaryingNode.varying(tangentGeometry.xyz, 'tangentLocal');
    static var tangentView:VaryingNode = VaryingNode.varying(ModelNode.modelViewMatrix.mul(ShaderNode.vec4(tangentLocal, 0)).xyz, 'tangentView').normalize();
    static var tangentWorld:VaryingNode = VaryingNode.varying(tangentView.transformDirection(CameraNode.cameraViewMatrix), 'tangentWorld').normalize();
    static var transformedTangentView:VaryingNode = tangentView.toVar('transformedTangentView');
    static var transformedTangentWorld:VaryingNode = transformedTangentView.transformDirection(CameraNode.cameraViewMatrix).normalize();
}