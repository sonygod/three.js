package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;
import three.js.math.OperatorNode;
import three.js.accessors.NormalNode;
import three.js.accessors.PositionNode;
import three.js.accessors.TextureNode;
import three.js.shadernode.ShaderNode;

class TriplanarTexturesNode extends Node {

    public var textureXNode:TextureNode;
    public var textureYNode:TextureNode;
    public var textureZNode:TextureNode;
    public var scaleNode:ShaderNode;
    public var positionNode:PositionNode;
    public var normalNode:NormalNode;

    public function new(textureXNode:TextureNode, ?textureYNode:TextureNode, ?textureZNode:TextureNode, ?scaleNode:ShaderNode = ShaderNode.float(1), ?positionNode:PositionNode = PositionNode.local, ?normalNode:NormalNode = NormalNode.local) {
        super('vec4');

        this.textureXNode = textureXNode;
        this.textureYNode = textureYNode;
        this.textureZNode = textureZNode;

        this.scaleNode = scaleNode;
        this.positionNode = positionNode;
        this.normalNode = normalNode;
    }

    override public function setup():ShaderNode {
        var bf:ShaderNode = normalNode.abs().normalize();
        bf = bf.div(bf.dot(ShaderNode.vec3(1.0)));

        var tx:ShaderNode = positionNode.yz.mul(scaleNode);
        var ty:ShaderNode = positionNode.zx.mul(scaleNode);
        var tz:ShaderNode = positionNode.xy.mul(scaleNode);

        var textureX:ShaderNode = textureXNode.value;
        var textureY:ShaderNode = (textureYNode == null) ? textureX : textureYNode.value;
        var textureZ:ShaderNode = (textureZNode == null) ? textureX : textureZNode.value;

        var cx:ShaderNode = ShaderNode.texture(textureX, tx).mul(bf.x);
        var cy:ShaderNode = ShaderNode.texture(textureY, ty).mul(bf.y);
        var cz:ShaderNode = ShaderNode.texture(textureZ, tz).mul(bf.z);

        return ShaderNode.add(cx, cy, cz);
    }

    public static var triplanarTextures:ShaderNode = nodeProxy(TriplanarTexturesNode);
    public static var triplanarTexture:Float->Float->Float->ShaderNode = function(params:Array<Float>) {
        return triplanarTextures.apply(params);
    }

    public static function main() {
        addNodeElement('triplanarTexture', triplanarTexture);
        addNodeClass('TriplanarTexturesNode', TriplanarTexturesNode);
    }
}