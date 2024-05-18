package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.nodes.CameraNode;
import three.js.nodes.NormalNode;
import three.js.nodes.PositionNode;
import three.js.shadernode.ShaderNode;

class ReflectVectorNode extends Node {

    public function new() {
        super('vec3');
    }

    public function getHash(builder:Dynamic) {
        return 'reflectVector';
    }

    public function setup():Vec3 {
        var reflectView:Vec3 = positionViewDirection.negate().reflect(transformedNormalView);
        return reflectView.transformDirection(cameraViewMatrix);
    }

}

// Export the class
@:keep
@:expose('ReflectVectorNode')
class ReflectVectorNode_ extends ReflectVectorNode {}

// Create an immutable version of the node
var reflectVector:ReflectVectorNode = nodeImmutable(new ReflectVectorNode_());

// Register the node class
Node.addNodeClass('ReflectVectorNode', ReflectVectorNode_);