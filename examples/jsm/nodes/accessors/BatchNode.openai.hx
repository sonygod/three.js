package three.js.nodes.accessors;

import three.core.Node;
import three.shadernode.ShaderNode;
import three.nodes.NormalNode;
import three.nodes.PositionNode;
import three.nodes.TextureNode;
import three.nodes.TextureSizeNode;
import three.core.AttributeNode;
import three.nodes.TangentNode;

class BatchNode extends Node {
    public var batchMesh:Dynamic;

    public var instanceColorNode:Null<ShaderNode>;
    public var batchingIdNode:Null<ShaderNode>;

    public function new(batchMesh:Dynamic) {
        super('void');
        this.batchMesh = batchMesh;
        this.instanceColorNode = null;
        this.batchingIdNode = null;
    }

    public function setup(builder:Dynamic) {
        // POSITION
        if (batchingIdNode == null) {
            batchingIdNode = AttributeNode.create('batchId');
        }

        var matriceTexture = batchMesh._matricesTexture;
        var size = TextureSizeNode.create(TextureNode.load(matriceTexture), 0);
        var j = ShaderNode.float(Std.int(batchingIdNode)).mul(4).getVar();
        var x = Std.int(j.mod(size));
        var y = Std.int(j) / Std.int(size);
        var batchingMatrix = new Mat4(
            TextureNode.load(matriceTexture, new IVec2(x, y)),
            TextureNode.load(matriceTexture, new IVec2(x + 1, y)),
            TextureNode.load(matriceTexture, new IVec2(x + 2, y)),
            TextureNode.load(matriceTexture, new IVec2(x + 3, y))
        );

        var bm = new Mat3(
            batchingMatrix[0].xyz,
            batchingMatrix[1].xyz,
            batchingMatrix[2].xyz
        );

        PositionNode.local.assign(batchingMatrix.mul(PositionNode.local));

        var transformedNormal = NormalNode.local.div(new Vec3(bm[0].dot(bm[0]), bm[1].dot(bm[1]), bm[2].dot(bm[2])));
        var batchingNormal = bm.mul(transformedNormal).xyz;
        NormalNode.local.assign(batchingNormal);

        if (builder.hasGeometryAttribute('tangent')) {
            TangentNode.local.mulAssign(bm);
        }
    }
}

#if haxe3
@:forward-vars(batchMesh, instanceColorNode, batchingIdNode)
#else
interface BatchNode {
    var batchMesh:Dynamic;
    var instanceColorNode:Null<ShaderNode>;
    var batchingIdNode:Null<ShaderNode>;
}
#end

class BatchNodeProxy {
    public static function create():BatchNode {
        return new BatchNode(null);
    }
}

Node.addNodeClass('batch', BatchNode);