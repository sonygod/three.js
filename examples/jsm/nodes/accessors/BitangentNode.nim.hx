import three.js.examples.jsm.nodes.core.VaryingNode;
import three.js.examples.jsm.nodes.accessors.CameraNode;
import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.accessors.TangentNode;

class BitangentNode {
    static function getBitangent(crossNormalTangent: Vect3) {
        return crossNormalTangent.mul(tangentGeometry.w).xyz();
    }

    static var bitangentGeometry = VaryingNode.varying(getBitangent(normalGeometry.cross(tangentGeometry))).normalize();
    static var bitangentLocal = VaryingNode.varying(getBitangent(normalLocal.cross(tangentLocal))).normalize();
    static var bitangentView = VaryingNode.varying(getBitangent(normalView.cross(tangentView))).normalize();
    static var bitangentWorld = VaryingNode.varying(getBitangent(normalWorld.cross(tangentWorld))).normalize();
    static var transformedBitangentView = getBitangent(transformedNormalView.cross(transformedTangentView)).normalize();
    static var transformedBitangentWorld = transformedBitangentView.transformDirection(cameraViewMatrix).normalize();
}