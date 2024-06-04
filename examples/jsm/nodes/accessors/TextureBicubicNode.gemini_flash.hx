import TempNode from "../core/TempNode";
import Node from "../core/Node";
import OperatorNode from "../math/OperatorNode";
import MathNode from "../math/MathNode";
import ShaderNode from "../shadernode/ShaderNode";

// Mipped Bicubic Texture Filtering by N8
// https://www.shadertoy.com/view/Dl2SDW

const bC = 1.0 / 6.0;

const w0 = (a: ShaderNode) -> ShaderNode {
    return OperatorNode.mul(bC, OperatorNode.mul(a, OperatorNode.mul(a, OperatorNode.mul(a, OperatorNode.add(a, 3.0)).negate()).sub(3.0))).add(1.0);
};

const w1 = (a: ShaderNode) -> ShaderNode {
    return OperatorNode.mul(bC, OperatorNode.mul(a, OperatorNode.mul(a, OperatorNode.mul(3.0, a).sub(6.0))).add(4.0));
};

const w2 = (a: ShaderNode) -> ShaderNode {
    return OperatorNode.mul(bC, OperatorNode.mul(a, OperatorNode.mul(a, OperatorNode.mul(-3.0, a).add(3.0)).add(3.0)).add(1.0));
};

const w3 = (a: ShaderNode) -> ShaderNode {
    return OperatorNode.mul(bC, MathNode.pow(a, 3));
};

const g0 = (a: ShaderNode) -> ShaderNode {
    return w0(a).add(w1(a));
};

const g1 = (a: ShaderNode) -> ShaderNode {
    return w2(a).add(w3(a));
};

// h0 and h1 are the two offset functions
const h0 = (a: ShaderNode) -> ShaderNode {
    return OperatorNode.add(-1.0, w1(a).div(w0(a).add(w1(a))));
};

const h1 = (a: ShaderNode) -> ShaderNode {
    return OperatorNode.add(1.0, w3(a).div(w2(a).add(w3(a))));
};

const bicubic = (textureNode: Node, texelSize: ShaderNode, lod: ShaderNode) -> ShaderNode {
    const uv = textureNode.uvNode;
    const uvScaled = OperatorNode.mul(uv, texelSize.zw).add(0.5);

    const iuv = MathNode.floor(uvScaled);
    const fuv = MathNode.fract(uvScaled);

    const g0x = g0(fuv.x);
    const g1x = g1(fuv.x);
    const h0x = h0(fuv.x);
    const h1x = h1(fuv.x);
    const h0y = h0(fuv.y);
    const h1y = h1(fuv.y);

    const p0 = ShaderNode.vec2(iuv.x.add(h0x), iuv.y.add(h0y)).sub(0.5).mul(texelSize.xy);
    const p1 = ShaderNode.vec2(iuv.x.add(h1x), iuv.y.add(h0y)).sub(0.5).mul(texelSize.xy);
    const p2 = ShaderNode.vec2(iuv.x.add(h0x), iuv.y.add(h1y)).sub(0.5).mul(texelSize.xy);
    const p3 = ShaderNode.vec2(iuv.x.add(h1x), iuv.y.add(h1y)).sub(0.5).mul(texelSize.xy);

    const a = g0(fuv.y).mul(OperatorNode.add(g0x.mul(textureNode.uv(p0).level(lod)), g1x.mul(textureNode.uv(p1).level(lod))));
    const b = g1(fuv.y).mul(OperatorNode.add(g0x.mul(textureNode.uv(p2).level(lod)), g1x.mul(textureNode.uv(p3).level(lod))));

    return a.add(b);
};

const textureBicubicMethod = (textureNode: Node, lodNode: ShaderNode) -> ShaderNode {
    const fLodSize = ShaderNode.vec2(textureNode.size(ShaderNode.int(lodNode)));
    const cLodSize = ShaderNode.vec2(textureNode.size(ShaderNode.int(lodNode.add(1.0))));
    const fLodSizeInv = OperatorNode.div(1.0, fLodSize);
    const cLodSizeInv = OperatorNode.div(1.0, cLodSize);
    const fSample = bicubic(textureNode, ShaderNode.vec4(fLodSizeInv, fLodSize), MathNode.floor(lodNode));
    const cSample = bicubic(textureNode, ShaderNode.vec4(cLodSizeInv, cLodSize), MathNode.ceil(lodNode));

    return MathNode.fract(lodNode).mix(fSample, cSample);
};

class TextureBicubicNode extends TempNode {
    public textureNode: Node;
    public blurNode: ShaderNode;

    public function new(textureNode: Node, blurNode: ShaderNode = ShaderNode.float(3)) {
        super('vec4');
        this.textureNode = textureNode;
        this.blurNode = blurNode;
    }

    override public function setup() -> ShaderNode {
        return textureBicubicMethod(this.textureNode, this.blurNode);
    }
}

class TextureBicubicNodeProxy {
    public static function _(textureNode: Node, blurNode: ShaderNode = ShaderNode.float(3)) -> TextureBicubicNode {
        return new TextureBicubicNode(textureNode, blurNode);
    }
}

var TextureBicubicNode: Dynamic = TextureBicubicNodeProxy;

ShaderNode.addNodeElement('bicubic', TextureBicubicNode);
Node.addNodeClass('TextureBicubicNode', TextureBicubicNode);