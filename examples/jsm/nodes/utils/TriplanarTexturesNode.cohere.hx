import Node from '../core/Node.hx';
import { add } from '../math/OperatorNode.hx';
import { normalLocal } from '../accessors/NormalNode.hx';
import { positionLocal } from '../accessors/PositionNode.hx';
import { texture } from '../accessors/TextureNode.hx';
import { addNodeElement, nodeProxy, float, vec3 } from '../shadernode/ShaderNode.hx';

class TriplanarTexturesNode extends Node {
    public var textureXNode:Node;
    public var textureYNode:Node;
    public var textureZNode:Node;
    public var scaleNode:Float;
    public var positionNode:PositionLocal;
    public var normalNode:NormalLocal;

    public function new(textureXNode:Node, textureYNode:Node = null, textureZNode:Node = null, scaleNode:Float = float(1), positionNode:PositionLocal = positionLocal, normalNode:NormalLocal = normalLocal) {
        super('vec4');
        this.textureXNode = textureXNode;
        this.textureYNode = textureYNode;
        this.textureZNode = textureZNode;
        this.scaleNode = scaleNode;
        this.positionNode = positionNode;
        this.normalNode = normalNode;
    }

    public function setup():Node {
        // Ref: https://github.com/keijiro/StandardTriplanar

        // Blending factor of triplanar mapping
        var bf = normalNode.abs().normalize();
        bf = bf.div(bf.dot(vec3(1.0)));

        // Triplanar mapping
        var tx = positionNode.yz.mul(scaleNode);
        var ty = positionNode.zx.mul(scaleNode);
        var tz = positionNode.xy.mul(scaleNode);

        // Base color
        var textureX = textureXNode.value;
        var textureY = if (textureYNode != null) textureYNode.value else textureX;
        var textureZ = if (textureZNode != null) textureZNode.value else textureX;

        var cx = texture(textureX, tx).mul(bf.x);
        var cy = texture(textureY, ty).mul(bf.y);
        var cz = texture(textureZ, tz).mul(bf.z);

        return add(cx, cy, cz);
    }
}

static function triplanarTextures(textureXNode:Node, textureYNode:Node = null, textureZNode:Node = null, scaleNode:Float = float(1), positionNode:PositionLocal = positionLocal, normalNode:NormalLocal = normalLocal) {
    return TriplanarTexturesNode(textureXNode, textureYNode, textureZNode, scaleNode, positionNode, normalNode);
}

static function triplanarTexture(...params) {
    return triplanarTextures(...params);
}

static function __init__() {
    addNodeElement('triplanarTexture', triplanarTexture);
    Node.addNodeClass('TriplanarTexturesNode', TriplanarTexturesNode);
}

export { TriplanarTexturesNode, triplanarTextures, triplanarTexture };