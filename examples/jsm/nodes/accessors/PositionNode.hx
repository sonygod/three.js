package three.js.examples.jvm.nodes.accessors;

import Node from '../core/Node.hx';
import AttributeNode from '../core/AttributeNode.hx';
import VaryingNode from '../core/VaryingNode.hx';
import MathNode from '../math/MathNode.hx';
import ModelNode from './ModelNode.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';

class PositionNode extends Node {

    public static inline var GEOMETRY:String = 'geometry';
    public static inline var LOCAL:String = 'local';
    public static inline var WORLD:String = 'world';
    public static inline var WORLD_DIRECTION:String = 'worldDirection';
    public static inline var VIEW:String = 'view';
    public static inline var VIEW_DIRECTION:String = 'viewDirection';

    private var scope:String;

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
        var scope:String = this.scope;
        var outputNode:Node = null;

        if (scope == GEOMETRY) {
            outputNode = AttributeNode.create('position', 'vec3');
        } else if (scope == LOCAL) {
            outputNode = VaryingNode.create(positionLocal);
        } else if (scope == WORLD) {
            var vertexPositionNode:Node = ModelNode.modelWorldMatrix.multiply(positionLocal);
            outputNode = VaryingNode.create(vertexPositionNode);
        } else if (scope == VIEW) {
            var vertexPositionNode:Node = ModelNode.modelViewMatrix.multiply(positionLocal);
            outputNode = VaryingNode.create(vertexPositionNode);
        } else if (scope == VIEW_DIRECTION) {
            var vertexPositionNode:Node = positionView.negate();
            outputNode = MathNode.normalize(VaryingNode.create(vertexPositionNode));
        } else if (scope == WORLD_DIRECTION) {
            var vertexPositionNode:Node = positionLocal.transformDirection(ModelNode.modelWorldMatrix);
            outputNode = MathNode.normalize(VaryingNode.create(vertexPositionNode));
        }

        return outputNode.build(builder, getNodeType(builder));
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.scope = this.scope;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.scope = data.scope;
    }
}

var positionGeometry:Node = ShaderNode.nodeImmutable(PositionNode, PositionNode.GEOMETRY);
var positionLocal:Node = ShaderNode.nodeImmutable(PositionNode, PositionNode.LOCAL).temp('Position');
var positionWorld:Node = ShaderNode.nodeImmutable(PositionNode, PositionNode.WORLD);
var positionWorldDirection:Node = ShaderNode.nodeImmutable(PositionNode, PositionNode.WORLD_DIRECTION);
var positionView:Node = ShaderNode.nodeImmutable(PositionNode, PositionNode.VIEW);
var positionViewDirection:Node = ShaderNode.nodeImmutable(PositionNode, PositionNode.VIEW_DIRECTION);

Node.addNodeClass('PositionNode', PositionNode);