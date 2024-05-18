Here is the converted Haxe code:
```
package three.js.examples.jm.nodes.display;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.accessors.UVNode;
import three.js.accessors.NormalNode;
import three.js.accessors.PositionNode;
import three.js.nodes.FrontFacingNode;
import three.js.shadernode.ShaderNode;

class BumpMapNode extends TempNode {
  var textureNode:ShaderNode;
  var scaleNode:ShaderNode;

  public function new(textureNode:ShaderNode, ?scaleNode:ShaderNode) {
    super('vec3');
    this.textureNode = textureNode;
    this.scaleNode = scaleNode;
  }

  override public function setup():ShaderNode {
    var bumpScale:Float = (scaleNode != null) ? scaleNode.value() : 1.0;
    var dHdxy = dHdxy_fwd({ textureNode: textureNode, bumpScale: bumpScale });
    return perturbNormalArb({ surf_pos: positionView, surf_norm: normalView, dHdxy: dHdxy });
  }

  static var dHdxy_fwd = tslFn((inputs:{ textureNode:ShaderNode, bumpScale:Float }) -> {
    var sampleTexture = (callback:UVNode->Void) -> {
      textureNode.cache().context({ getUV: (texNode:ShaderNode) -> callback(texNode.uvNode != null ? texNode.uvNode : UVNode.get()), forceUVContext: true });
    };

    var Hll:Float = sampleTexture((uvNode:UVNode) -> uvNode.value());
    var dx:Float = sampleTexture((uvNode:UVNode) -> uvNode.add(uvNode.dFdx()).value());
    var dy:Float = sampleTexture((uvNode:UVNode) -> uvNode.add(uvNode.dFdy()).value());

    return vec2(dx - Hll, dy - Hll).mul(bumpScale);
  });

  static var perturbNormalArb = tslFn((inputs:{ surf_pos:ShaderNode, surf_norm:ShaderNode, dHdxy:ShaderNode }) -> {
    var vSigmaX:ShaderNode = inputs.surf_pos.dFdx().normalize();
    var vSigmaY:ShaderNode = inputs.surf_pos.dFdy().normalize();
    var vN:ShaderNode = inputs.surf_norm;

    var R1:ShaderNode = vSigmaY.cross(vN);
    var R2:ShaderNode = vN.cross(vSigmaX);

    var fDet:Float = vSigmaX.dot(R1).mul(FrontFacingNode.faceDirection);
    var vGrad:ShaderNode = fDet.sign().mul(dHdxy.x.mul(R1).add(dHdxy.y.mul(R2)));

    return fDet.abs().mul(vN).sub(vGrad).normalize();
  });
}

ShaderNode.bumpMap = nodeProxy(BumpMapNode);

addNodeElement('bumpMap', bumpMap);

addNodeClass('BumpMapNode', BumpMapNode);
```
Note that I had to make some assumptions about the Haxe types and syntax, as well as the conversion of the JavaScript code. Please review the code carefully to ensure it meets your requirements.