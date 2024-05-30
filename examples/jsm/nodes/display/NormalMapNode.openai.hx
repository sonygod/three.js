package three.js.examples.jsm.nodes.display;

import three.js.core.TempNode;
import three.math.OperatorNode;
import three.accessors.ModelNode;
import three.accessors.NormalNode;
import three.accessors.PositionNode;
import three.accessors.AccessorsUtils;
import three.accessors.UVNode;
import three.nodes.FrontFacingNode;

class NormalMapNode extends TempNode {
    public var node:Node;
    public var scaleNode:Node;
    public var normalMapType:TangentSpaceNormalMap;

    public function new(node:Node, scaleNode:Node = null) {
        super('vec3');

        this.node = node;
        this.scaleNode = scaleNode;

        this.normalMapType = TangentSpaceNormalMap;
    }

    public function setup(builder:Builder):Node {
        var normalMap:Node = node.mul(2.0).sub(1.0);

        if (scaleNode != null) {
            normalMap = new Vec3(normalMap.xy.mul(scaleNode), normalMap.z);
        }

        var outputNode:Node = null;

        if (normalMapType == ObjectSpaceNormalMap) {
            outputNode = ModelNode.modelNormalMatrix.mul(normalMap).normalize();
        } else if (normalMapType == TangentSpaceNormalMap) {
            var tangent:Bool = builder.hasGeometryAttribute('tangent');

            if (tangent) {
                outputNode = AccessorsUtils.TBNViewMatrix.mul(normalMap).normalize();
            } else {
                outputNode = perturbNormal2Arb({
                    eye_pos: PositionNode.positionView,
                    surf_norm: NormalNode.normalView,
                    mapN: normalMap,
                    uv: UVNode.uv()
                });
            }
        }

        return outputNode;
    }
}

private function perturbNormal2Arb(inputs:Object):Node {
    var eye_pos:Node = inputs.eye_pos;
    var surf_norm:Node = inputs.surf_norm;
    var mapN:Node = inputs.mapN;
    var uv:Node = inputs.uv;

    var q0:Node = eye_pos.dFdx();
    var q1:Node = eye_pos.dFdy();
    var st0:Node = uv.dFdx();
    var st1:Node = uv.dFdy();

    var N:Node = surf_norm; // normalized

    var q1perp:Node = q1.cross(N);
    var q0perp:Node = N.cross(q0);

    var T:Node = q1perp.mul(st0.x).add(q0perp.mul(st1.x));
    var B:Node = q1perp.mul(st0.y).add(q0perp.mul(st1.y));

    var det:Node = T.dot(T).max(B.dot(B));
    var scale:Node = FrontFacingNode.faceDirection.mul(det.inverseSqrt());

    return new OperatorNode('add', [T.mul(mapN.x, scale), B.mul(mapN.y, scale), N.mul(mapN.z)]).normalize();
}

// register node
 extern class NodeProxy {
    static var normalMap(default, null):NormalMapNode;
}

NodeProxy.normalMap = nodeProxy(NormalMapNode);

initNodeClass("NormalMapNode", NormalMapNode);