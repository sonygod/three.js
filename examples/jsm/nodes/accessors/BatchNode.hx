package three.js.examples.javascript.nodes.accessors;

import three.js.core.Node;
import three.js.core.AttributeNode;
import three.js.shadernode.ShaderNode;
import three.js.nodes.NormalNode;
import three.js.nodes.PositionNode;
import three.js.nodes.TangentNode;
import three.js.nodes.TextureNode;
import three.js.nodes.TextureSizeNode;

class BatchNode extends Node {

    public var batchMesh:Dynamic;

    public var instanceColorNode:Null<ShaderNode>;

    public var batchingIdNode:Null<AttributeNode>;

    public function new(batchMesh:Dynamic) {
        super('void');

        this.batchMesh = batchMesh;

        this.instanceColorNode = null;

        this.batchingIdNode = null;
    }

    public function setup(builder:Dynamic) {
        // POSITION

        if (this.batchingIdNode == null) {
            this.batchingIdNode = attribute('batchId');
        }

        var matriceTexture = this.batchMesh._matricesTexture;

        var size = textureSize(textureLoad(matriceTexture), 0);
        var j = float(int(this.batchingIdNode)).mul(4).toVar();
        var x = int(j.mod(size));
        var y = int(j).div(int(size));
        var batchingMatrix = new Mat4(
            textureLoad(matriceTexture, new IVec2(x, y)),
            textureLoad(matriceTexture, new IVec2(x + 1, y)),
            textureLoad(matriceTexture, new IVec2(x + 2, y)),
            textureLoad(matriceTexture, new IVec2(x + 3, y))
        );

        var bm = new Mat3(
            batchingMatrix.getCol(0).xyz,
            batchingMatrix.getCol(1).xyz,
            batchingMatrix.getCol(2).xyz
        );

        positionLocal.assign(batchingMatrix.mul(positionLocal));

        var transformedNormal = normalLocal.div(new Vec3(bm.getCol(0).dot(bm.getCol(0)), bm.getCol(1).dot(bm.getCol(1)), bm.getCol(2).dot(bm.getCol(2))));

        var batchingNormal = bm.mul(transformedNormal).xyz;

        normalLocal.assign(batchingNormal);

        if (builder.hasGeometryAttribute('tangent')) {
            tangentLocal.mulAssign(bm);
        }
    }
}

extern class BatchNodeBuilder {
    static public function batch():BatchNode {
        return nodeProxy(BatchNode);
    }
}

addNodeClass('batch', BatchNode);