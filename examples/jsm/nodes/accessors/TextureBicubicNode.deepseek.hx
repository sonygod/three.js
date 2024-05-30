import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.math.OperatorNode;
import three.js.examples.jsm.nodes.math.MathNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class TextureBicubicNode extends TempNode {

    public var textureNode:ShaderNode;
    public var blurNode:ShaderNode;

    public function new(textureNode:ShaderNode, blurNode:ShaderNode = ShaderNode.float(3)) {
        super('vec4');
        this.textureNode = textureNode;
        this.blurNode = blurNode;
    }

    public function setup():ShaderNode {
        return textureBicubicMethod(this.textureNode, this.blurNode);
    }

    static function textureBicubicMethod(textureNode:ShaderNode, lodNode:ShaderNode):ShaderNode {
        var fLodSize = ShaderNode.vec2(textureNode.size(ShaderNode.int(lodNode)));
        var cLodSize = ShaderNode.vec2(textureNode.size(ShaderNode.int(lodNode.add(1.0))));
        var fLodSizeInv = ShaderNode.div(1.0, fLodSize);
        var cLodSizeInv = ShaderNode.div(1.0, cLodSize);
        var fSample = bicubic(textureNode, ShaderNode.vec4(fLodSizeInv, fLodSize), ShaderNode.floor(lodNode));
        var cSample = bicubic(textureNode, ShaderNode.vec4(cLodSizeInv, cLodSize), ShaderNode.ceil(lodNode));
        return ShaderNode.fract(lodNode).mix(fSample, cSample);
    }

    static function bicubic(textureNode:ShaderNode, texelSize:ShaderNode, lod:ShaderNode):ShaderNode {
        var uv = textureNode.uvNode;
        var uvScaled = ShaderNode.mul(uv, texelSize.zw).add(0.5);
        var iuv = ShaderNode.floor(uvScaled);
        var fuv = ShaderNode.fract(uvScaled);
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
        var a = g0(fuv.y).mul(ShaderNode.add(g0x.mul(textureNode.uv(p0).level(lod)), g1x.mul(textureNode.uv(p1).level(lod))));
        var b = g1(fuv.y).mul(ShaderNode.add(g0x.mul(textureNode.uv(p2).level(lod)), g1x.mul(textureNode.uv(p3).level(lod))));
        return a.add(b);
    }

    static function w0(a:ShaderNode):ShaderNode {
        return ShaderNode.mul(bC, ShaderNode.mul(a, ShaderNode.mul(a, a.negate().add(3.0)).sub(3.0)).add(1.0));
    }

    static function w1(a:ShaderNode):ShaderNode {
        return ShaderNode.mul(bC, ShaderNode.mul(a, ShaderNode.mul(3.0, a).sub(6.0)).add(4.0));
    }

    static function w2(a:ShaderNode):ShaderNode {
        return ShaderNode.mul(bC, ShaderNode.mul(a, ShaderNode.mul(-3.0, a).add(3.0)).add(3.0));
    }

    static function w3(a:ShaderNode):ShaderNode {
        return ShaderNode.mul(bC, ShaderNode.pow(a, 3));
    }

    static function g0(a:ShaderNode):ShaderNode {
        return w0(a).add(w1(a));
    }

    static function g1(a:ShaderNode):ShaderNode {
        return w2(a).add(w3(a));
    }

    static function h0(a:ShaderNode):ShaderNode {
        return ShaderNode.add(-1.0, ShaderNode.div(w1(a), w0(a).add(w1(a))));
    }

    static function h1(a:ShaderNode):ShaderNode {
        return ShaderNode.add(1.0, ShaderNode.div(w3(a), w2(a).add(w3(a))));
    }

    static var bC:Float = 1.0 / 6.0;
}

Node.addNodeClass('TextureBicubicNode', TextureBicubicNode);
Node.addNodeElement('bicubic', ShaderNode.nodeProxy(TextureBicubicNode));