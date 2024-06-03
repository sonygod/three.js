import FogNode from './FogNode';
import MathNode from '../math/MathNode';
import Node from '../core/Node';
import ShaderNode from '../shadernode/ShaderNode';

class FogRangeNode extends FogNode {

    public var isFogRangeNode:Bool = true;
    public var nearNode:Dynamic;
    public var farNode:Dynamic;

    public function new(colorNode:Dynamic, nearNode:Dynamic, farNode:Dynamic) {
        super(colorNode);
        this.nearNode = nearNode;
        this.farNode = farNode;
    }

    public function setup(builder:Dynamic):Dynamic {
        var viewZ = this.getViewZNode(builder);
        return MathNode.smoothstep(this.nearNode, this.farNode, viewZ);
    }
}

export default FogRangeNode;

var rangeFog = ShaderNode.nodeProxy(FogRangeNode);
ShaderNode.addNodeElement('rangeFog', rangeFog);

Node.addNodeClass('FogRangeNode', FogRangeNode);