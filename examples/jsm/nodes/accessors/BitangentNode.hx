package three.js.examples.jsm.nodes.accessors;

import three.js.core.VaryingNode;
import three.js.nodes.CameraNode;
import three.js.nodes.NormalNode;
import three.js.nodes.TangentNode;

using Lambda;

class BitangentNode {
    static var getBitangent = function(crossNormalTangent:Vec3) {
        return crossNormalTangent.multiply(new Vec3(0, 0, 0, tangentGeometry.w)).xyz;
    }

    public static var bitangentGeometry:Vec3 = VaryingNode.varying(getBitangent(NormalNode.normalGeometry.cross(TangentNode.tangentGeometry))).normalize();
    public static var bitangentLocal:Vec3 = VaryingNode.varying(getBitangent(NormalNode.normalLocal.cross(TangentNode.tangentLocal))).normalize();
    public static var bitangentView:Vec3 = VaryingNode.varying(getBitangent(NormalNode.normalView.cross(TangentNode.tangentView))).normalize();
    public static var bitangentWorld:Vec3 = VaryingNode.varying(getBitangent(NormalNode.normalWorld.cross(TangentNode.tangentWorld))).normalize();
    public static var transformedBitangentView:Vec3 = getBitangent(NormalNode.transformedNormalView.cross(TangentNode.transformedTangentView)).normalize();
    public static var transformedBitangentWorld:Vec3 = transformedBitangentView.transformDirection(CameraNode.cameraViewMatrix).normalize();
}