import Node from "../core/Node";
import AttributeNode from "../core/AttributeNode";
import VaryingNode from "../core/VaryingNode";
import MathNode from "../math/MathNode";
import ModelNode from "./ModelNode";
import ShaderNode from "../shadernode/ShaderNode";

class PositionNode extends Node {

    public static GEOMETRY:String = "geometry";
    public static LOCAL:String = "local";
    public static WORLD:String = "world";
    public static WORLD_DIRECTION:String = "worldDirection";
    public static VIEW:String = "view";
    public static VIEW_DIRECTION:String = "viewDirection";

    public scope:String;

    public constructor(scope:String = PositionNode.LOCAL) {
        super("vec3");
        this.scope = scope;
    }

    public isGlobal():Bool {
        return true;
    }

    public getHash(builder:Dynamic):String {
        return "position-" + this.scope;
    }

    public generate(builder:Dynamic):Dynamic {
        let outputNode:Dynamic = null;

        switch (this.scope) {
            case PositionNode.GEOMETRY:
                outputNode = AttributeNode.attribute("position", "vec3");
                break;
            case PositionNode.LOCAL:
                outputNode = VaryingNode.varying(positionGeometry);
                break;
            case PositionNode.WORLD:
                outputNode = VaryingNode.varying(ModelNode.modelWorldMatrix.mul(positionLocal));
                break;
            case PositionNode.VIEW:
                outputNode = VaryingNode.varying(ModelNode.modelViewMatrix.mul(positionLocal));
                break;
            case PositionNode.VIEW_DIRECTION:
                outputNode = MathNode.normalize(VaryingNode.varying(positionView.negate()));
                break;
            case PositionNode.WORLD_DIRECTION:
                outputNode = MathNode.normalize(VaryingNode.varying(positionLocal.transformDirection(ModelNode.modelWorldMatrix)));
                break;
        }

        return outputNode.build(builder, this.getNodeType(builder));
    }

    public serialize(data:Dynamic):Void {
        super.serialize(data);
        data.scope = this.scope;
    }

    public deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.scope = data.scope;
    }

}

var positionGeometry:PositionNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.GEOMETRY);
var positionLocal:PositionNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.LOCAL).temp("Position");
var positionWorld:PositionNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.WORLD);
var positionWorldDirection:PositionNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.WORLD_DIRECTION);
var positionView:PositionNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.VIEW);
var positionViewDirection:PositionNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.VIEW_DIRECTION);

export default PositionNode;