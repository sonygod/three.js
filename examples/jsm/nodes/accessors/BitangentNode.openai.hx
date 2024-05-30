package three.js.examples.jsm.nodes.accessors;

import three.js.core.VaryingNode;

class BitangentNode {
    static public var bitangentGeometry:VaryingNode = new VaryingNode(getBitangent(normalGeometry.cross(tangentGeometry)).normalize());
    static public var bitangentLocal:VaryingNode = new VaryingNode(getBitangent(normalLocal.cross(tangentLocal)).normalize());
    static public var bitangentView:VaryingNode = new VaryingNode(getBitangent(normalView.cross(tangentView)).normalize());
    static public var bitangentWorld:VaryingNode = new VaryingNode(getBitangent(normalWorld.cross(tangentWorld)).normalize());
    static public var transformedBitangentView:Vector3 = getBitangent(transformedNormalView.cross(transformedTangentView)).normalize();
    static public var transformedBitangentWorld:Vector3 = transformedBitangentView.transformDirection(cameraViewMatrix).normalize();

    static function getBitangent(crossNormalTangent:Vector3):Vector3 {
        return crossNormalTangent.mul(tangentGeometry.w).xyz;
    }
}