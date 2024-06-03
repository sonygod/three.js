import js.Array;
import js.html.Lib;
import js.Boot;

import nodes.core.Node;
import nodes.core.constants.NodeUpdateType;
import nodes.shadernode.ShaderNode;
import nodes.core.AttributeNode;
import nodes.accessors.ReferenceNode;
import nodes.math.OperatorNode;
import nodes.accessors.NormalNode;
import nodes.accessors.PositionNode;
import nodes.accessors.TangentNode;
import nodes.core.UniformNode;
import nodes.accessors.BufferNode;

class SkinningNode extends Node {

    public var skinnedMesh:Dynamic;
    public var useReference:Bool;

    public var skinIndexNode:nodes.core.AttributeNode;
    public var skinWeightNode:nodes.core.AttributeNode;
    public var bindMatrixNode:Dynamic;
    public var bindMatrixInverseNode:Dynamic;
    public var boneMatricesNode:Dynamic;

    public function new(skinnedMesh:Dynamic, useReference:Bool = false) {
        super("void");

        this.skinnedMesh = skinnedMesh;
        this.useReference = useReference;

        this.updateType = NodeUpdateType.OBJECT;

        this.skinIndexNode = AttributeNode.attribute("skinIndex", "uvec4");
        this.skinWeightNode = AttributeNode.attribute("skinWeight", "vec4");

        var bindMatrixNode:Dynamic;
        var bindMatrixInverseNode:Dynamic;
        var boneMatricesNode:Dynamic;

        if (useReference) {
            bindMatrixNode = ReferenceNode.reference("bindMatrix", "mat4");
            bindMatrixInverseNode = ReferenceNode.reference("bindMatrixInverse", "mat4");
            boneMatricesNode = ReferenceNode.referenceBuffer("skeleton.boneMatrices", "mat4", skinnedMesh.skeleton.bones.length);
        } else {
            bindMatrixNode = UniformNode.uniform(skinnedMesh.bindMatrix, "mat4");
            bindMatrixInverseNode = UniformNode.uniform(skinnedMesh.bindMatrixInverse, "mat4");
            boneMatricesNode = BufferNode.buffer(skinnedMesh.skeleton.boneMatrices, "mat4", skinnedMesh.skeleton.bones.length);
        }

        this.bindMatrixNode = bindMatrixNode;
        this.bindMatrixInverseNode = bindMatrixInverseNode;
        this.boneMatricesNode = boneMatricesNode;
    }

    public function setup(builder:Dynamic):Void {
        var boneMatX = this.boneMatricesNode.element(this.skinIndexNode.x);
        var boneMatY = this.boneMatricesNode.element(this.skinIndexNode.y);
        var boneMatZ = this.boneMatricesNode.element(this.skinIndexNode.z);
        var boneMatW = this.boneMatricesNode.element(this.skinIndexNode.w);

        var skinVertex = this.bindMatrixNode.mul(PositionNode.positionLocal);

        var skinned = OperatorNode.add(
            boneMatX.mul(this.skinWeightNode.x).mul(skinVertex),
            boneMatY.mul(this.skinWeightNode.y).mul(skinVertex),
            boneMatZ.mul(this.skinWeightNode.z).mul(skinVertex),
            boneMatW.mul(this.skinWeightNode.w).mul(skinVertex)
        );

        var skinPosition = this.bindMatrixInverseNode.mul(skinned).xyz;

        var skinMatrix = OperatorNode.add(
            this.skinWeightNode.x.mul(boneMatX),
            this.skinWeightNode.y.mul(boneMatY),
            this.skinWeightNode.z.mul(boneMatZ),
            this.skinWeightNode.w.mul(boneMatW)
        );

        skinMatrix = this.bindMatrixInverseNode.mul(skinMatrix).mul(this.bindMatrixNode);

        var skinNormal = skinMatrix.transformDirection(NormalNode.normalLocal).xyz;

        PositionNode.positionLocal.assign(skinPosition);
        NormalNode.normalLocal.assign(skinNormal);

        if (builder.hasGeometryAttribute("tangent")) {
            TangentNode.tangentLocal.assign(skinNormal);
        }
    }

    public function generate(builder:Dynamic, output:String):Dynamic {
        if (output !== "void") {
            return PositionNode.positionLocal.build(builder, output);
        }
        return null;
    }

    public function update(frame:Dynamic):Void {
        var object = this.useReference ? frame.object : this.skinnedMesh;

        object.skeleton.update();
    }
}

export function skinning(skinnedMesh:Dynamic):Dynamic {
    return ShaderNode.nodeObject(new SkinningNode(skinnedMesh));
}

export function skinningReference(skinnedMesh:Dynamic):Dynamic {
    return ShaderNode.nodeObject(new SkinningNode(skinnedMesh, true));
}

Node.addNodeClass("SkinningNode", Boot.getClass<SkinningNode>());