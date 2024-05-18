package three.js.examples.javascript.nodes.accessors;

import three.js.examples.javascript.nodes.Object3DNode;
import three.js.core.Node;

class ModelNode extends Object3DNode {

    public static inline var VIEW_MATRIX:Int = 0;
    public static inline var DIRECTION:Int = 1;
    public static inline var NORMAL_MATRIX:Int = 2;
    public static inline var WORLD_MATRIX:Int = 3;
    public static inline var POSITION:Int = 4;
    public static inline var SCALE:Int = 5;
    public static inline var VIEW_POSITION:Int = 6;

    public function new(?scope:Int = VIEW_MATRIX) {
        super(scope);
    }

    override public function update(frame:Dynamic) {
        object3d = frame.object;
        super.update(frame);
    }

    public static var modelDirection:ShaderNode = nodeImmutable(ModelNode, DIRECTION);
    public static var modelViewMatrix:ShaderNode = nodeImmutable(ModelNode, VIEW_MATRIX).label('modelViewMatrix').temp('ModelViewMatrix');
    public static var modelNormalMatrix:ShaderNode = nodeImmutable(ModelNode, NORMAL_MATRIX);
    public static var modelWorldMatrix:ShaderNode = nodeImmutable(ModelNode, WORLD_MATRIX);
    public static var modelPosition:ShaderNode = nodeImmutable(ModelNode, POSITION);
    public static var modelScale:ShaderNode = nodeImmutable(ModelNode, SCALE);
    public static var modelViewPosition:ShaderNode = nodeImmutable(ModelNode, VIEW_POSITION);
}

Node.addNodeClass('ModelNode', ModelNode);