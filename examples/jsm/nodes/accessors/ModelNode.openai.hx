package three.js.examples.jsm.nodes.accessors;

import three.js.examples.jsm.nodes.Object3DNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class ModelNode extends Object3DNode {
    public static inline var VIEW_MATRIX = 0;
    public static inline var DIRECTION = 1;
    public static inline var NORMAL_MATRIX = 2;
    public static inline var WORLD_MATRIX = 3;
    public static inline var POSITION = 4;
    public static inline var SCALE = 5;
    public static inline var VIEW_POSITION = 6;

    public function new(scope = VIEW_MATRIX) {
        super(scope);
    }

    override public function update(frame: Dynamic) {
        object3d = frame.object;
        super.update(frame);
    }
}

class ModelNodeMeta {
    public static var modelDirection = ShaderNode.nodeImmutable(ModelNode, ModelNode.DIRECTION);
    public static var modelViewMatrix = ShaderNode.node Immutable(ModelNode, ModelNode.VIEW_MATRIX).label('modelViewMatrix').temp('ModelViewMatrix');
    public static var modelNormalMatrix = ShaderNode.nodeImmutable(ModelNode, ModelNode.NORMAL_MATRIX);
    public static var modelWorldMatrix = ShaderNode.nodeImmutable(ModelNode, ModelNode.WORLD_MATRIX);
    public static var modelPosition = ShaderNode.nodeImmutable(ModelNode, ModelNode.POSITION);
    public static var modelScale = ShaderNode.nodeImmutable(ModelNode, ModelNode.SCALE);
    public static var modelViewPosition = ShaderNode.nodeImmutable(ModelNode, ModelNode.VIEW_POSITION);
}

Node.addNodeClass('ModelNode', ModelNode);