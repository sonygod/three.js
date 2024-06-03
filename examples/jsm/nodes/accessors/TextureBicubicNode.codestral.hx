import js.Browser.window;

import three.nodes.core.TempNode;
import three.nodes.core.Node;
import three.nodes.math.OperatorNode;
import three.nodes.math.MathNode;
import three.nodes.shadernode.ShaderNode;

class TextureBicubicNode extends TempNode {

    public var textureNode:ShaderNode;
    public var blurNode:ShaderNode;

    public function new(textureNode:ShaderNode, blurNode:ShaderNode = ShaderNode.float(3)) {
        super('vec4');
        this.textureNode = textureNode;
        this.blurNode = blurNode;
    }

    override public function setup() {
        return textureBicubicMethod(this.textureNode, this.blurNode);
    }
}

function textureBicubicMethod(textureNode:ShaderNode, lodNode:ShaderNode) {
    var fLodSize = ShaderNode.vec2(textureNode.size(ShaderNode.int(lodNode)));
    var cLodSize = ShaderNode.vec2(textureNode.size(ShaderNode.int(lodNode.add(1.0))));
    var fLodSizeInv = OperatorNode.div(1.0, fLodSize);
    var cLodSizeInv = OperatorNode.div(1.0, cLodSize);
    var fSample = bicubic(textureNode, ShaderNode.vec4(fLodSizeInv, fLodSize), MathNode.floor(lodNode));
    var cSample = bicubic(textureNode, ShaderNode.vec4(cLodSizeInv, cLodSize), MathNode.ceil(lodNode));
    return MathNode.fract(lodNode).mix(fSample, cSample);
}

function bicubic(textureNode:ShaderNode, texelSize:ShaderNode, lod:ShaderNode) {
    var uv = textureNode.uvNode;
    var uvScaled = OperatorNode.mul(uv, texelSize.zw).add(0.5);
    var iuv = MathNode.floor(uvScaled);
    var fuv = MathNode.fract(uvScaled);
    var g0x = g0(fuv.x);
    var g1x = g1(fuv.x);
    var h0x = h0(fuv.x);
    var h1x = h1(fuv.x);
    var h0y = h0(fuv.y);
    var h1y = h1(fuv.y);
    var p0 = ShaderNode.vec2(iuv.x.add(h0x), iuv.y.add(h0y)).sub(0.5).mul(texelSize.xy);
    var p1 = ShaderNode.vec2(iuv.x.add(h1x), iuv.y.add(h0y)).sub(0.5).mul(texelSize.xy);
    var p2 = ShaderNode.vec2(iuv.x.add(h0x), iuv.y.add(h1y)).sub(0.5).mul(texelSize.xy);
    var p3 = ShaderNode.vec2(iuv.x.add(h1x), iuv.y.add(h1y)).sub(0.5).mul(texelSize.xy);
    var a = g0(fuv.y).mul(OperatorNode.add(g0x.mul(textureNode.uv(p0).level(lod)), g1x.mul(textureNode.uv(p1).level(lod))));
    var b = g1(fuv.y).mul(OperatorNode.add(g0x.mul(textureNode.uv(p2).level(lod)), g1x.mul(textureNode.uv(p3).level(lod))));
    return a.add(b);
}

function g1(a:ShaderNode) {
    return w2(a).add(w3(a));
}

function g0(a:ShaderNode) {
    return w0(a).add(w1(a));
}

function h1(a:ShaderNode) {
    return OperatorNode.add(1.0, w3(a).div(w2(a).add(w3(a))));
}

function h0(a:ShaderNode) {
    return OperatorNode.add(-1.0, w1(a).div(w0(a).add(w1(a))));
}

function w3(a:ShaderNode) {
    return OperatorNode.mul(1.0 / 6.0, MathNode.pow(a, 3));
}

function w2(a:ShaderNode) {
    return OperatorNode.mul(1.0 / 6.0, OperatorNode.mul(a, OperatorNode.mul(a, OperatorNode.mul(-3.0, a)).add(3.0)).add(1.0));
}

function w1(a:ShaderNode) {
    return OperatorNode.mul(1.0 / 6.0, OperatorNode.mul(a, OperatorNode.mul(a, OperatorNode.mul(3.0, a)).sub(6.0)).add(4.0));
}

function w0(a:ShaderNode) {
    return OperatorNode.mul(1.0 / 6.0, OperatorNode.mul(a, OperatorNode.mul(a, a.negate().add(3.0)).sub(3.0)).add(1.0));
}

Node.addNodeClass("TextureBicubicNode", TextureBicubicNode);
ShaderNode.addNodeElement("bicubic", ShaderNode.nodeProxy(TextureBicubicNode));

window.TextureBicubicNode = TextureBicubicNode;