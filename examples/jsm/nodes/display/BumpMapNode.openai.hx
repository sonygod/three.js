package three.js.examples.jvm.nodes.display;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.accessors.UVNode;
import three.js.accessors.NormalNode;
import three.js.accessors.PositionNode;
import three.js.nodes.display.FrontFacingNode;
import three.js.shadernode.ShaderNode;

class BumpMapNode extends TempNode<Vector3> {
  public var textureNode:Node;
  public var scaleNode:Node;

  public function new(textureNode:Node, scaleNode:Node = null) {
    super("vec3");
    this.textureNode = textureNode;
    this.scaleNode = scaleNode;
  }

  override public function setup():Node {
    var bumpScale:Float = (scaleNode != null) ? scaleNode.getValue() : 1.0;
    var dHdxy = dHdxy_fwd({ textureNode: textureNode, bumpScale: bumpScale });
    return perturbNormalArb({ surf_pos: positionView, surf_norm: normalView, dHdxy: dHdxy });
  }
}

class dHdxy_fwd {
  public static function apply(textureNode:Node, bumpScale:Float):Vec2 {
    var sampleTexture = function(callback:UVNode->Void) {
      textureNode.cache().context({ getUV: function(texNode:Node) callback(UVNode(texNode)), forceUVContext: true });
    };

    var Hll:Float = sampleTexture(function(uvNode:UVNode) uvNode.getValue());

    return new Vec2(
      sampleTexture(function(uvNode:UVNode) uvNode.add(uvNode.dFdx()).getValue()) - Hll,
      sampleTexture(function(uvNode:UVNode) uvNode.add(uvNode.dFdy()).getValue()) - Hll
    ).mul(bumpScale);
  }
}

class perturbNormalArb {
  public static function apply(inputs:{ surf_pos:Node, surf_norm:Node, dHdxy:Vec2 }):Vec3 {
    var surf_pos:Node = inputs.surf_pos;
    var surf_norm:Node = inputs.surf_norm;
    var dHdxy:Vec2 = inputs.dHdxy;

    var vSigmaX:Vec3 = surf_pos.dFdx().normalize();
    var vSigmaY:Vec3 = surf_pos.dFdy().normalize();
    var vN:Vec3 = surf_norm.normalize();

    var R1:Vec3 = vSigmaY.cross(vN);
    var R2:Vec3 = vN.cross(vSigmaX);

    var fDet:Float = vSigmaX.dot(R1) * faceDirection;

    var vGrad:Vec3 = fDet.sign() * (dHdxy.x * R1 + dHdxy.y * R2);

    return fDet.abs() * surf_norm.sub(vGrad).normalize();
  }
}

var bumpMap:BumpMapNode->Node = nodeProxy(BumpMapNode);

addNodeElement('bumpMap', bumpMap);

addNodeClass('BumpMapNode', BumpMapNode);