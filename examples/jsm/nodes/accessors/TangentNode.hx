package three.js.examples.jvm.nodes.accessors;

import three.js.core.AttributeNode;
import three.js.core.VaryingNode;
import three.js.nodes.CameraNode;
import three.js.nodes.ModelNode;
import three.js.shader.ShaderNode;

using Lambda;

class TangentNode {
    static var tangentGeometry:AttributeNode = tslFn((stack, builder) -> {
        if (!builder.geometry.hasAttribute('tangent')) {
            builder.geometry.computeTangents();
        }
        return new AttributeNode('tangent', 'vec4');
    })();

    static var tangentLocal:VaryingNode = new VaryingNode(tangentGeometry.xyz, 'tangentLocal');
    static var tangentView:VaryingNode = new VaryingNode((modelViewMatrix.mul(new Vec4(tangentLocal, 0))).xyz, 'tangentView').normalize();
    static var tangentWorld:VaryingNode = new VaryingNode(tangentView.transformDirection(cameraViewMatrix), 'tangentWorld').normalize();
    static var transformedTangentView:VaryingNode = tangentView.toVar('transformedTangentView');
    static var transformedTangentWorld:VaryingNode = transformedTangentView.transformDirection(cameraViewMatrix).normalize();
}