import Node from '../core/Node.hx';
import AttributeNode from '../core/AttributeNode.hx';
import VaryingNode from '../core/VaryingNode.hx';
import MathNode from '../math/MathNode.hx';
import ModelNode from './ModelNode.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';

class PositionNode extends Node {

    public var scope: String;

    public function new(scope = PositionNode.LOCAL) {
        super("vec3");
        this.scope = scope;
    }

    public function isGlobal(): Bool {
        return true;
    }

    public function getHash(): String {
        return "position-${this.scope}";
    }

    public function generate(builder: Any): Any {
        var outputNode = null;

        switch (this.scope) {
            case PositionNode.GEOMETRY:
                outputNode = AttributeNode.attribute("position", "vec3");
                break;
            case PositionNode.LOCAL:
                outputNode = VaryingNode.varying(positionLocal);
                break;
            case PositionNode.WORLD:
                var vertexPositionNode = ModelNode.modelWorldMatrix.mul(positionLocal);
                outputNode = VaryingNode.varying(vertexPositionNode);
                break;
            case PositionNode.VIEW:
                var vertexPositionNode = ModelNode.modelViewMatrix.mul(positionLocal);
                outputNode = VaryingNode.varying(vertexPositionNode);
                break;
            case PositionNode.VIEW_DIRECTION:
                var vertexPositionNode = positionView.negate();
                outputNode = MathNode.normalize(VaryingNode.varying(vertexPositionNode));
                break;
            case PositionNode.WORLD_DIRECTION:
                var vertexPositionNode = positionLocal.transformDirection(ModelNode.modelWorldMatrix);
                outputNode = MathNode.normalize(VaryingNode.varying(vertexPositionNode));
                break;
        }

        return outputNode.build(builder, this.getNodeType(builder));
    }

    public override function serialize(data: Any) {
        super.serialize(data);
        data.scope = this.scope;
    }

    public override function deserialize(data: Any) {
        super.deserialize(data);
        this.scope = data.scope;
    }

}

PositionNode.GEOMETRY = "geometry";
PositionNode.LOCAL = "local";
PositionNode.WORLD = "world";
PositionNode.WORLD_DIRECTION = "worldDirection";
PositionNode.VIEW = "view";
PositionNode.VIEW_DIRECTION = "viewDirection";

var positionGeometry = ShaderNode.nodeImmutable(PositionNode, PositionNode.GEOMETRY);
var positionLocal = ShaderNode.nodeImmutable(PositionNode, PositionNode.LOCAL).temp("Position");
var positionWorld = ShaderNode.nodeImmutable(PositionNode, PositionNode.WORLD);
var positionWorldDirection = ShaderNode.nodeImmutable(PositionNode, PositionNode.WORLD_DIRECTION);
var positionView = ShaderNode.nodeImmutable(PositionNode, PositionNode.VIEW);
var positionViewDirection = ShaderNode.nodeImmutable(PositionNode, PositionNode.VIEW_DIRECTION);

Node.addNodeClass("PositionNode", PositionNode);