import js.Browser.document;
import three.js.nodes.core.Node;
import three.js.nodes.math.OperatorNode;
import three.js.nodes.accessors.NormalNode;
import three.js.nodes.accessors.PositionNode;
import three.js.nodes.accessors.TextureNode;
import three.js.nodes.shadernode.ShaderNode;

class TriplanarTexturesNode extends Node {

    public var textureXNode: Node;
    public var textureYNode: Node;
    public var textureZNode: Node;
    public var scaleNode: Node;
    public var positionNode: Node;
    public var normalNode: Node;

    public function new(textureXNode: Node, textureYNode: Node = null, textureZNode: Node = null, scaleNode: Node = ShaderNode.float(1), positionNode: Node = PositionNode.positionLocal, normalNode: Node = NormalNode.normalLocal) {
        super("vec4");

        this.textureXNode = textureXNode;
        this.textureYNode = textureYNode;
        this.textureZNode = textureZNode;
        this.scaleNode = scaleNode;
        this.positionNode = positionNode;
        this.normalNode = normalNode;
    }

    public function setup(): Node {
        var bf = this.normalNode.abs().normalize();
        bf = bf.div(bf.dot(ShaderNode.vec3(1.0)));

        var tx = this.positionNode.yz.mul(this.scaleNode);
        var ty = this.positionNode.zx.mul(this.scaleNode);
        var tz = this.positionNode.xy.mul(this.scaleNode);

        var textureX = this.textureXNode.value;
        var textureY = this.textureYNode !== null ? this.textureYNode.value : textureX;
        var textureZ = this.textureZNode !== null ? this.textureZNode.value : textureX;

        var cx = TextureNode.texture(textureX, tx).mul(bf.x);
        var cy = TextureNode.texture(textureY, ty).mul(bf.y);
        var cz = TextureNode.texture(textureZ, tz).mul(bf.z);

        return OperatorNode.add(cx, cy, cz);
    }
}

class TriplanarTextures {
    public static function call(textureXNode: Node, textureYNode: Node = null, textureZNode: Node = null, scaleNode: Node = ShaderNode.float(1), positionNode: Node = PositionNode.positionLocal, normalNode: Node = NormalNode.normalLocal): Node {
        return new TriplanarTexturesNode(textureXNode, textureYNode, textureZNode, scaleNode, positionNode, normalNode);
    }
}

ShaderNode.addNodeElement("triplanarTexture", TriplanarTextures.call);