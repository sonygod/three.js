import AttributeNode.attribute;
import VaryingNode.varying;
import CameraNode.cameraViewMatrix;
import ModelNode.modelViewMatrix;
import ShaderNode.tslFn;
import ShaderNode.vec4;

class TangentNode {
    static function tangentGeometry():Dynamic {
        return tslFn(function(stack, builder) {
            if (!builder.geometry.hasAttribute('tangent')) {
                builder.geometry.computeTangents();
            }
            return attribute('tangent', 'vec4');
        })();
    }

    static var tangentLocal = varying(tangentGeometry().xyz, 'tangentLocal');
    static var tangentView = varying(modelViewMatrix.mul(vec4(tangentLocal, 0)).xyz, 'tangentView').normalize();
    static var tangentWorld = varying(tangentView.transformDirection(cameraViewMatrix), 'tangentWorld').normalize();
    static var transformedTangentView = tangentView.toVar('transformedTangentView');
    static var transformedTangentWorld = transformedTangentView.transformDirection(cameraViewMatrix).normalize();
}