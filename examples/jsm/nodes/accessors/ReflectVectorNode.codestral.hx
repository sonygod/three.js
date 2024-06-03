import Node;
import NodeClass;
import CameraNode.cameraViewMatrix;
import NormalNode.transformedNormalView;
import PositionNode.positionViewDirection;
import ShaderNode.nodeImmutable;

class ReflectVectorNode extends Node {

    public function new() {
        super('vec3');
    }

    public function getHash(): String {
        return 'reflectVector';
    }

    public function setup(): Dynamic {
        var reflectView = positionViewDirection.negate().reflect(transformedNormalView);
        return reflectView.transformDirection(cameraViewMatrix);
    }

}

class ReflectVectorNodeWrapper {
    public static var reflectVector: Dynamic = nodeImmutable(ReflectVectorNode);
}

NodeClass.addNodeClass('ReflectVectorNode', ReflectVectorNode);