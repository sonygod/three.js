package jsm.nodes.accessors;

import jsm.nodes.core.Node;
import jsm.nodes.Object3DNode;
import jsm.shadernode.ShaderNode;

@:native
class ModelNode extends Object3DNode {
    public function new(scope: Int = ModelNode.VIEW_MATRIX) {
        super(scope);
    }

    public function update(frame: Dynamic) {
        this.object3d = frame.object;
        super.update(frame);
    }
}

class ModelNodeExports {
    public static inline var modelDirection = ShaderNode.nodeImmutable(ModelNode, ModelNode.DIRECTION);
    public static inline var modelViewMatrix = ShaderNode.nodeImmutable(ModelNode, ModelNode.VIEW_MATRIX).label('modelViewMatrix').temp('ModelViewMatrix');
    public static inline var modelNormalMatrix = ShaderNode.nodeImmutable(ModelNode, ModelNode.NORMAL_MATRIX);
    public static inline var modelWorldMatrix = ShaderNode.nodeImmutable(ModelNode, ModelNode.WORLD_MATRIX);
    public static inline var modelPosition = ShaderNode.nodeImmutable(ModelNode, ModelNode.POSITION);
    public static inline var modelScale = ShaderNode.nodeImmutable(ModelNode, ModelNode.SCALE);
    public static inline var modelViewPosition = ShaderNode.nodeImmutable(ModelNode, ModelNode.VIEW_POSITION);

    public static function main() {
        Node.addNodeClass('ModelNode', ModelNode);
    }
}