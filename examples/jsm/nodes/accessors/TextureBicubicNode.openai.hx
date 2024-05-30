package three.js.examples.javascript.nodes.accessors;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.math.OperatorNode;
import three.js.math.MathNode;
import three.js.shader.ShaderNode;

class TextureBicubicNode extends TempNode {
    // Mipped Bicubic Texture Filtering by N8
    // https://www.shadertoy.com/view/Dl2SDW

    static inline var bC:Float = 1.0 / 6.0;

    static function w0(a:Float):Float {
        return bC * a * (a * (a - 3.0) + 1.0);
    }

    static function w1(a:Float):Float {
        return bC * a * (3.0 * a - 6.0) + 4.0;
    }

    static function w2(a:Float):Float {
        return bC * a * (a * (-3.0 + a) + 3.0) + 1.0;
    }

    static function w3(a:Float):Float {
        return bC * Math.pow(a, 3);
    }

    static function g0(a:Float):Float {
        return w0(a) + w1(a);
    }

    static function g1(a:Float):Float {
        return w2(a) + w3(a);
    }

    static function h0(a:Float):Float {
        return -1.0 + w1(a) / (w0(a) + w1(a));
    }

    static function h1(a:Float):Float {
        return 1.0 + w3(a) / (w2(a) + w3(a));
    }

    static function bicubic(textureNode:ShaderNode, texelSize:Vec4, lod:Float):Float {
        var uv = textureNode.uvNode;
        var uvScaled = (uv * texelSize.zw) + 0.5;
        var iuv = Math.floor(uvScaled);
        var fuv = uvScaled - iuv;

        var g0x = g0(fuv.x);
        var g1x = g1(fuv.x);
        var h0x = h0(fuv.x);
        var h1x = h1(fuv.x);
        var h0y = h0(fuv.y);
        var h1y = h1(fuv.y);

        var p0 = new Vec2(iuv.x + h0x, iuv.y + h0y) - 0.5;
        p0 = p0 * texelSize.xy;
        var p1 = new Vec2(iuv.x + h1x, iuv.y + h0y) - 0.5;
        p1 = p1 * texelSize.xy;
        var p2 = new Vec2(iuv.x + h0x, iuv.y + h1y) - 0.5;
        p2 = p2 * texelSize.xy;
        var p3 = new Vec2(iuv.x + h1x, iuv.y + h1y) - 0.5;
        p3 = p3 * texelSize.xy;

        var a = g0(fuv.y) * (g0x * textureNode.uv(p0).level(lod) + g1x * textureNode.uv(p1).level(lod));
        var b = g1(fuv.y) * (g0x * textureNode.uv(p2).level(lod) + g1x * textureNode.uv(p3).level(lod));

        return a + b;
    }

    static function textureBicubicMethod(textureNode:ShaderNode, lodNode:Float):Float {
        var fLodSize = new Vec2(textureNode.size(Math.floor(lodNode)));
        var cLodSize = new Vec2(textureNode.size(Math.ceil(lodNode)));
        var fLodSizeInv = new Vec2(1.0 / fLodSize.x, 1.0 / fLodSize.y);
        var cLodSizeInv = new Vec2(1.0 / cLodSize.x, 1.0 / cLodSize.y);
        var fSample = bicubic(textureNode, new Vec4(fLodSizeInv.x, fLodSizeInv.y, fLodSize.x, fLodSize.y), Math.floor(lodNode));
        var cSample = bicubic(textureNode, new Vec4(cLodSizeInv.x, cLodSizeInv.y, cLodSize.x, cLodSize.y), Math.ceil(lodNode));

        return Math.fract(lodNode) * (fSample - cSample) + cSample;
    }

    public var textureNode:ShaderNode;
    public var blurNode:Float;

    public function new(textureNode:ShaderNode, blurNode:Float = 3.0) {
        super('vec4');

        this.textureNode = textureNode;
        this.blurNode = blurNode;
    }

    override function setup():Float {
        return textureBicubicMethod(textureNode, blurNode);
    }
}

// Register the node
addNodeElement('bicubic', nodeProxy(TextureBicubicNode));

addNodeClass('TextureBicubicNode', TextureBicubicNode);