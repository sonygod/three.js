import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.accessors.UVNode;
import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.nodes.display.FrontFacingNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class BumpMapNode extends TempNode {

    public var textureNode:ShaderNode;
    public var scaleNode:ShaderNode;

    public function new(textureNode:ShaderNode, scaleNode:ShaderNode = null) {
        super('vec3');
        this.textureNode = textureNode;
        this.scaleNode = scaleNode;
    }

    public function setup():ShaderNode {
        var bumpScale = this.scaleNode != null ? this.scaleNode : 1;
        var dHdxy = dHdxy_fwd({textureNode: this.textureNode, bumpScale: bumpScale});

        return perturbNormalArb({
            surf_pos: PositionNode.positionView,
            surf_norm: NormalNode.normalView,
            dHdxy: dHdxy
        });
    }

    static function dHdxy_fwd(inputs:{textureNode:ShaderNode, bumpScale:Float}):ShaderNode {
        var textureNode = inputs.textureNode;
        var bumpScale = inputs.bumpScale;

        var sampleTexture = function(callback:ShaderNode->ShaderNode) {
            return textureNode.cache().context({getUV: function(texNode) {
                return callback(texNode.uvNode || UVNode.uv());
            }, forceUVContext: true});
        };

        var Hll = ShaderNode.float(sampleTexture(function(uvNode) {
            return uvNode;
        }));

        return ShaderNode.vec2(
            ShaderNode.float(sampleTexture(function(uvNode) {
                return uvNode.add(uvNode.dFdx());
            })).sub(Hll),
            ShaderNode.float(sampleTexture(function(uvNode) {
                return uvNode.add(uvNode.dFdy());
            })).sub(Hll)
        ).mul(bumpScale);
    }

    static function perturbNormalArb(inputs:{surf_pos:ShaderNode, surf_norm:ShaderNode, dHdxy:ShaderNode}):ShaderNode {
        var surf_pos = inputs.surf_pos;
        var surf_norm = inputs.surf_norm;
        var dHdxy = inputs.dHdxy;

        var vSigmaX = surf_pos.dFdx().normalize();
        var vSigmaY = surf_pos.dFdy().normalize();
        var vN = surf_norm;

        var R1 = vSigmaY.cross(vN);
        var R2 = vN.cross(vSigmaX);

        var fDet = vSigmaX.dot(R1).mul(FrontFacingNode.faceDirection);

        var vGrad = fDet.sign().mul(dHdxy.x.mul(R1).add(dHdxy.y.mul(R2)));

        return fDet.abs().mul(surf_norm).sub(vGrad).normalize();
    }
}

Node.addNodeElement('bumpMap', BumpMapNode.bumpMap);
Node.addNodeClass('BumpMapNode', BumpMapNode);