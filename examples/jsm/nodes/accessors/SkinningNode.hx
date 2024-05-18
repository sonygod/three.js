Here is the converted Haxe code:
```
package three.js.examples.jm.nodes.accessors;

import three.js.core.Node;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;
import three.js.core.AttributeNode;
import three.js.nodes.ReferenceNode;
import three.js.math.OperatorNode;
import three.js.nodes.NormalNode;
import three.js.nodes.PositionNode;
import three.js.nodes.TangentNode;
import three.js.core.UniformNode;
import three.js.nodes.BufferNode;

class SkinningNode extends Node {

    public var skinnedMesh:Dynamic;
    public var useReference:Bool;
    public var updateType:NodeUpdateType;

    public var skinIndexNode:AttributeNode;
    public var skinWeightNode:AttributeNode;
    public var bindMatrixNode:Dynamic;
    public var bindMatrixInverseNode:Dynamic;
    public var boneMatricesNode:Dynamic;

    public function new(skinnedMesh:Dynamic, useReference:Bool = false) {
        super('void');

        this.skinnedMesh = skinnedMesh;
        this.useReference = useReference;

        this.updateType = NodeUpdateType.OBJECT;

        this.skinIndexNode = AttributeNode.create('skinIndex', 'uvec4');
        this.skinWeightNode = AttributeNode.create('skinWeight', 'vec4');

        if (useReference) {
            bindMatrixNode = ReferenceNode.create('bindMatrix', 'mat4');
            bindMatrixInverseNode = ReferenceNode.create('bindMatrixInverse', 'mat4');
            boneMatricesNode = ReferenceNode.createBuffer('skeleton.boneMatrices', 'mat4', skinnedMesh.skeleton.bones.length);
        } else {
            bindMatrixNode = UniformNode.createFromValue(skinnedMesh.bindMatrix, 'mat4');
            bindMatrixInverseNode = UniformNode.createFromValue(skinnedMesh.bindMatrixInverse, 'mat4');
            boneMatricesNode = BufferNode.createFromValues(skinnedMesh.skeleton.boneMatrices, 'mat4', skinnedMesh.skeleton.bones.length);
        }

        this.bindMatrixNode = bindMatrixNode;
        this.bindMatrixInverseNode = bindMatrixInverseNode;
        this.boneMatricesNode = boneMatricesNode;
    }

    public function setup(builder:Dynamic) {
        var skinIndexNode = this.skinIndexNode;
        var skinWeightNode = this.skinWeightNode;
        var bindMatrixNode = this.bindMatrixNode;
        var bindMatrixInverseNode = this.bindMatrixInverseNode;
        var boneMatricesNode = this.boneMatricesNode;

        var boneMatX = boneMatricesNode.getElement(skinIndexNode.x);
        var boneMatY = boneMatricesNode.getElement(skinIndexNode.y);
        var boneMatZ = boneMatricesNode.getElement(skinIndexNode.z);
        var boneMatW = boneMatricesNode.getElement(skinIndexNode.w);

        // POSITION

        var skinVertex = bindMatrixNode.mul(PositionNode.local);

        var skinned = OperatorNode.add(
            boneMatX.mul(skinWeightNode.x).mul(skinVertex),
            boneMatY.mul(skinWeightNode.y).mul(skinVertex),
            boneMatZ.mul(skinWeightNode.z).mul(skinVertex),
            boneMatW.mul(skinWeightNode.w).mul(skinVertex)
        );

        var skinPosition = bindMatrixInverseNode.mul(skinned).xyz;

        // NORMAL

        var skinMatrix = OperatorNode.add(
            skinWeightNode.x.mul(boneMatX),
            skinWeightNode.y.mul(boneMatY),
            skinWeightNode.z.mul(boneMatZ),
            skinWeightNode.w.mul(boneMatW)
        );

        skinMatrix = bindMatrixInverseNode.mul(skinMatrix).mul(bindMatrixNode);

        var skinNormal = skinMatrix.transformDirection(NormalNode.local).xyz;

        // ASSIGNS

        PositionNode.local.assign(skinPosition);
        NormalNode.local.assign(skinNormal);

        if (builder.hasGeometryAttribute('tangent')) {
            TangentNode.local.assign(skinNormal);
        }
    }

    public function generate(builder:Dynamic, output:String) {
        if (output != 'void') {
            return PositionNode.local.build(builder, output);
        }
        return null;
    }

    public function update(frame:Dynamic) {
        var object:Dynamic = useReference ? frame.object : skinnedMesh;
        object.skeleton.update();
    }

    public static function skinning(skinnedMesh:Dynamic) {
        return nodeObject(new SkinningNode(skinnedMesh));
    }

    public static function skinningReference(skinnedMesh:Dynamic) {
        return nodeObject(new SkinningNode(skinnedMesh, true));
    }
}
```
Note that I had to make some assumptions about the Haxe equivalents of the JavaScript classes and functions used in the original code. Specifically, I assumed that:

* `Node`, `NodeUpdateType`, and `ShaderNode` are part of the `three.js.core` package.
* `AttributeNode`, `ReferenceNode`, `OperatorNode`, `NormalNode`, `PositionNode`, and `TangentNode` are part of the `three.js.nodes` package.
* `UniformNode` and `BufferNode` are part of the `three.js.core` package.
* `nodeObject` is a function that wraps a `SkinningNode` instance in a `ShaderNode` object.

If these assumptions are not correct, you may need to modify the Haxe code accordingly.