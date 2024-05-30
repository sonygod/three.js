package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.examples.jsm.nodes.CameraNode;
import three.js.examples.jsm.nodes.NormalNode;
import three.js.examples.jsm.nodes.PositionNode;
import three.js.shader.ShaderNode;

class ReflectVectorNode extends Node {

    public function new() {
        super('vec3');
    }

    public function getHash(builder:Dynamic):String {
        return 'reflectVector';
    }

    public function setup():Vector3 {
        var reflectView = positionViewDirection.negate().reflect(transformedNormalView);
        return reflectView.transformDirection(cameraViewMatrix);
    }

    public static var reflectVector:ReflectVectorNode = nodeImmutable(new ReflectVectorNode());
}

Node.addNodeClass('ReflectVectorNode', ReflectVectorNode);