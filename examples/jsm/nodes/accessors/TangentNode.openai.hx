package three.nodes.accessors;

import three.core.AttributeNode;
import three.core.VaryingNode;
import three.nodes.CameraNode;
import three.nodes.ModelNode;
import three.shader.ShaderNode;

class TangentNode {
    static public var tangentGeometry:AttributeNode = ShaderNode.tslFn(function(stack, builder) {
        if (!builder.geometry.getAttribute("tangent")) {
            builder.geometry.computeTangents();
        }
        return new AttributeNode("tangent", "vec4");
    })();

    static public var tangentLocal:VaryingNode = new VaryingNode(tangentGeometry.xyz, "tangentLocal");
    static public var tangentView:VaryingNode = new VaryingNode(ModelNode.modelViewMatrix.multVec(new Vec4(tangentLocal, 0)).xyz, "tangentView").normalize();
    static public var tangentWorld:VaryingNode = new VaryingNode(tangentView.transformDirection(CameraNode.cameraViewMatrix), "tangentWorld").normalize();
    static public var transformedTangentView:VaryingNode = tangentView.toVar("transformedTangentView");
    static public var transformedTangentWorld:VaryingNode = transformedTangentView.transformDirection(CameraNode.cameraViewMatrix).normalize();
}