package three.js.examples.jsm.nodes.accessors;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.math.OperatorNode;
import three.js.math.MathNode;
import three.js.shadernode.ShaderNode;

class TextureBicubicNode extends TempNode {

  public var textureNode:Dynamic;
  public var blurNode:Float;

  public function new(textureNode:Dynamic, blurNode:Float = 3.0) {
    super('vec4');
    this.textureNode = textureNode;
    this.blurNode = blurNode;
  }

  override public function setup():Dynamic {
    return textureBicubicMethod(this.textureNode, this.blurNode);
  }
}

class TextureBicubicMethod {
  static public function textureBicubicMethod(textureNode:Dynamic, lodNode:Float):Float {
    var fLodSize:Vector2 = textureNode.size(Std.int(lodNode));
    var cLodSize:Vector2 = textureNode.size(Std.int(lodNode + 1.0));
    var fLodSizeInv:Vector2 = new Vector2(1.0 / fLodSize.x, 1.0 / fLodSize.y);
    var cLodSizeInv:Vector2 = new Vector2(1.0 / cLodSize.x, 1.0 / cLodSize.y);
    var fSample:Float = bicubic(textureNode, new Vector4(fLodSizeInv.x, fLodSizeInv.y, fLodSize.x, fLodSize.y), Std.int(lodNode));
    var cSample:Float = bicubic(textureNode, new Vector4(cLodSizeInv.x, cLodSizeInv.y, cLodSize.x, cLodSize.y), Std.int(lodNode + 1.0));
    return lerp(fSample, cSample, fract(lodNode));
  }

  static private function bicubic(textureNode:Dynamic, texelSize:Vector4, lod:Int):Float {
    var uv:Vector2 = textureNode.uvNode;
    var uvScaled:Vector2 = new Vector2(uv.x * texelSize.z + 0.5, uv.y * texelSize.w + 0.5);
    var iuv:Vector2 = new Vector2(Std.int(uvScaled.x), Std.int(uvScaled.y));
    var fuv:Vector2 = new Vector2(uvScaled.x - iuv.x, uvScaled.y - iuv.y);
    var g0x:Float = g0(fuv.x);
    var g1x:Float = g1(fuv.x);
    var h0x:Float = h0(fuv.x);
    var h1x:Float = h1(fuv.x);
    var h0y:Float = h0(fuv.y);
    var h1y:Float = h1(fuv.y);
    var p0:Vector2 = new Vector2(iuv.x + h0x, iuv.y + h0y);
    var p1:Vector2 = new Vector2(iuv.x + h1x, iuv.y + h0y);
    var p2:Vector2 = new Vector2(iuv.x + h0x, iuv.y + h1y);
    var p3:Vector2 = new Vector2(iuv.x + h1x, iuv.y + h1y);
    p0 = p0.sub(new Vector2(0.5, 0.5)).mul(texelSize.xy);
    p1 = p1.sub(new Vector2(0.5, 0.5)).mul(texelSize.xy);
    p2 = p2.sub(new Vector2(0.5, 0.5)).mul(texelSize.xy);
    p3 = p3.sub(new Vector2(0.5, 0.5)).mul(texelSize.xy);
    var a:Float = g0(fuv.y) * (g0x * textureNode.uv(p0).level(lod) + g1x * textureNode.uv(p1).level(lod));
    var b:Float = g1(fuv.y) * (g0x * textureNode.uv(p2).level(lod) + g1x * textureNode.uv(p3).level(lod));
    return a + b;
  }

  static private function g0(a:Float):Float {
    var bC:Float = 1.0 / 6.0;
    return bC * a * a * (a - 3.0) + 1.0;
  }

  static private function g1(a:Float):Float {
    var bC:Float = 1.0 / 6.0;
    return bC * a * a * (3.0 * a - 6.0) + 4.0;
  }

  static private function h0(a:Float):Float {
    return -1.0 + w1(a) / (w0(a) + w1(a));
  }

  static private function h1(a:Float):Float {
    return 1.0 + w3(a) / (w2(a) + w3(a));
  }

  static private function w0(a:Float):Float {
    var bC:Float = 1.0 / 6.0;
    return bC * a * a * (a - 3.0) + 1.0;
  }

  static private function w1(a:Float):Float {
    var bC:Float = 1.0 / 6.0;
    return bC * a * a * (3.0 * a - 6.0) + 4.0;
  }

  static private function w2(a:Float):Float {
    var bC:Float = 1.0 / 6.0;
    return bC * a * a * (-3.0 * a + 3.0) + 3.0;
  }

  static private function w3(a:Float):Float {
    var bC:Float = 1.0 / 6.0;
    return bC * a * a * a;
  }
}

// Register node
ShaderNode.addNodeElement('bicubic', TextureBicubicNode);
Node.addNodeClass('TextureBicubicNode', TextureBicubicNode);