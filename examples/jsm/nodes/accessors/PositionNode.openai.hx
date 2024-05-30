package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.core.AttributeNode;
import three.js.core.VaryingNode;
import three.js.math.MathNode;
import three.js.nodes.accessors.ModelNode;

class PositionNode extends Node {
    public static inline var GEOMETRY = 'geometry';
    public static inline var LOCAL = 'local';
    public static inline var WORLD = 'world';
    public static inline var WORLD_DIRECTION = 'worldDirection';
    public static inline var VIEW = 'view';
    public static inline var VIEW_DIRECTION = 'viewDirection';

    public var scope:String;

    public function new(?scope:String = LOCAL) {
        super('vec3');

        this.scope = scope;
    }

    public function isGlobal():Bool {
        return true;
    }

    public function getHash(builder:Dynamic):String {
        return 'position-${this.scope}';
    }

    public function generate(builder:Dynamic):Node {
        var scope = this.scope;
        var outputNode:Node = null;

        if (scope == GEOMETRY) {
            outputNode = AttributeNode.attribute('position', 'vec3');
        } else if (scope == LOCAL) {
            outputNode = VaryingNode.varying(positionLocal);
        } else if (scope == WORLD) {
            var vertexPositionNode = ModelNode.modelWorldMatrix.mul(positionLocal);
            outputNode = VaryingNode.varying(vertexPositionNode);
        } else if (scope == VIEW) {
            var vertexPositionNode = ModelNode.modelViewMatrix.mul(positionLocal);
            outputNode = VaryingNode.varying(vertexPositionNode);
        } else if (scope == VIEW_DIRECTION) {
            var vertexPositionNode = positionView.negate();
            outputNode = MathNode.normalize(VaryingNode.varying(vertexPositionNode));
        } else if (scope == WORLD_DIRECTION) {
            var vertexPositionNode = positionLocal.transformDirection(ModelNode.modelWorldMatrix);
            outputNode = MathNode.normalize(VaryingNode.varying(vertexPositionNode));
        }

        return outputNode.build(builder, getNodeTypes(builder));
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.scope = this.scope;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        this.scope = data.scope;
    }
}

var positionGeometry = Node.nodeImmutable(new PositionNode(PositionNode.GEOMETRY));
var positionLocal = Node.nodeImmutable(new PositionNode(PositionNode.LOCAL), 'Position');
var positionWorld = Node.nodeImmutable(new PositionNode(PositionNode.WORLD));
var positionWorldDirection = Node.nodeImmutable(new PositionNode(PositionNode.WORLD_DIRECTION));
var positionView = Node.nodeImmutable(new PositionNode(PositionNode.VIEW));
var positionViewDirection = Node.nodeImmutable(new PositionNode(PositionNode.VIEW_DIRECTION));

Node.addNodeClass('PositionNode', PositionNode);