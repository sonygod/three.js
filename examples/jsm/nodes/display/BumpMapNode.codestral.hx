import three.nodes.core.TempNode;
import three.nodes.core.Node;
import three.nodes.accessors.UVNode;
import three.nodes.accessors.NormalNode;
import three.nodes.accessors.PositionNode;
import three.nodes.display.FrontFacingNode;
import three.nodes.shadernode.ShaderNode;

class BumpMapNode extends TempNode {
    public var textureNode:ShaderNode;
    public var scaleNode:ShaderNode;

    public function new(textureNode:ShaderNode, scaleNode:ShaderNode = null) {
        super("vec3");
        this.textureNode = textureNode;
        this.scaleNode = scaleNode;
    }

    public function setup():ShaderNode {
        var bumpScale = this.scaleNode !== null ? this.scaleNode : 1;
        var dHdxy = dHdxy_fwd({textureNode: this.textureNode, bumpScale: bumpScale});

        return perturbNormalArb({
            surf_pos: PositionNode.positionView,
            surf_norm: NormalNode.normalView,
            dHdxy: dHdxy
        });
    }
}

function dHdxy_fwd(args:Dynamic):ShaderNode {
    var textureNode = args.textureNode;
    var bumpScale = args.bumpScale;

    var sampleTexture = function(callback:Dynamic -> ShaderNode):ShaderNode {
        return textureNode.cache().context({
            getUV: function(texNode:ShaderNode):ShaderNode {
                return callback(texNode.uvNode || UVNode.uv());
            },
            forceUVContext: true
        });
    };

    var Hll = ShaderNode.float(sampleTexture(${ uvNode -> uvNode }));

    return ShaderNode.vec2(
        ShaderNode.float(sampleTexture(${ uvNode -> uvNode.add(uvNode.dFdx()) })).sub(Hll),
        ShaderNode.float(sampleTexture(${ uvNode -> uvNode.add(uvNode.dFdy()) })).sub(Hll)
    ).mul(bumpScale);
}

function perturbNormalArb(inputs:Dynamic):ShaderNode {
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

function bumpMap(textureNode:ShaderNode, scaleNode:ShaderNode = null):ShaderNode {
    return ShaderNode.nodeProxy(new BumpMapNode(textureNode, scaleNode));
}

ShaderNode.addNodeElement("bumpMap", bumpMap);
Node.addNodeClass("BumpMapNode", BumpMapNode);