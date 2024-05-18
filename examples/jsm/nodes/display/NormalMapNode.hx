package three.js.examples.jm.nodes.display;

import three.js.core.TempNode;
import three.math.OperatorNode;
import three.accessors.ModelNode;
import three.accessors.NormalNode;
import three.accessors.PositionNode;
import three.accessors.AccessorsUtils;
import three.accessors.UVNode;
import three.nodes.display.FrontFacingNode;
import three.nodes.ShaderNode;

using three.nodes.display.NormalMapNode;

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

    override public function setup(builder:NodeBuilder):Node {
        var normalMapType = this.normalMapType;
        var scaleNode = this.scaleNode;

        var normalMap = node.mul(2.0).sub(1.0);

        if (scaleNode != null) {
            normalMap = new Vec3(normalMap.x * scaleNode, normalMap.y * scaleNode, normalMap.z);
        }

        var outputNode:Node = null;

        if (normalMapType == ObjectSpaceNormalMap) {
            outputNode = ModelNode.modelNormalMatrix.mul(normalMap).normalize();
        } else if (normalMapType == TangentSpaceNormalMap) {
            var tangent = builder.hasGeometryAttribute('tangent');
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

function perturbNormal2Arb(inputs:{ eye_pos:Node, surf_norm:Node, mapN:Node, uv:Node }):Node {
    var eye_pos = inputs.eye_pos;
    var surf_norm = inputs.surf_norm;
    var mapN = inputs.mapN;
    var uv = inputs.uv;

    var q0 = eye_pos.dFdx();
    var q1 = eye_pos.dFdy();
    var st0 = uv.dFdx();
    var st1 = uv.dFdy();

    var N = surf_norm.normalize();

    var q1perp = q1.cross(N);
    var q0perp = N.cross(q0);

    var T = q1perp.mul(st0.x).add(q0perp.mul(st1.x));
    var B = q1perp.mul(st0.y).add(q0perp.mul(st1.y));

    var det = T.dot(T).max(B.dot(B));
    var scale = FrontFacingNode.faceDirection.mul(det.inverseSqrt());

    return OperatorNode.add(T.mul(mapN.x, scale), B.mul(mapN.y, scale), N.mul(mapN.z)).normalize();
}

class ShaderNode {
    public static var tslFn:(inputs:Dynamic)->Node = null;
    public static var nodeProxy:(node:Node)->Node = null;
    public static var addNodeElement:(name:String, node:Node)->Void = null;
    public static var addNodeClass:(name:String, nodeClass:Class<Dynamic>)->Void = null;
}

ShaderNode.tslFn = perturbNormal2Arb;

var normalMap = ShaderNode.nodeProxy(new NormalMapNode(null));

ShaderNode.addNodeElement('normalMap', normalMap);

ShaderNode.addNodeClass('NormalMapNode', NormalMapNode);