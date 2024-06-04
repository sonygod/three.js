import core.AttributeNode;
import core.VaryingNode;
import CameraNode;
import ModelNode;
import ShaderNode.ShaderNode;
import ShaderNode.vec4;

class TangentGeometry extends ShaderNode {

    public function new() {
        super();
    }

    override public function generate(stack:ShaderNode.Stack, builder:ShaderNode.Builder) {
        if (!builder.geometry.hasAttribute('tangent')) {
            builder.geometry.computeTangents();
        }
        return AttributeNode.attribute('tangent', 'vec4');
    }
}

var tangentGeometry = new TangentGeometry();

var tangentLocal = new VaryingNode(tangentGeometry.xyz, 'tangentLocal');
var tangentView = new VaryingNode(ModelNode.modelViewMatrix.mul(vec4(tangentLocal, 0)).xyz, 'tangentView').normalize();
var tangentWorld = new VaryingNode(tangentView.transformDirection(CameraNode.cameraViewMatrix), 'tangentWorld').normalize();
var transformedTangentView = tangentView.toVar('transformedTangentView');
var transformedTangentWorld = transformedTangentView.transformDirection(CameraNode.cameraViewMatrix).normalize();