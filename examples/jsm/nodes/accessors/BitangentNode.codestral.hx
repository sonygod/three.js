import js.Browser;
import js.html.compat.Vector3;
import js.html.compat.Matrix4;
import VaryingNode;
import CameraNode;
import NormalNode;
import TangentNode;

class BitangentNode {
    static function getBitangent(crossNormalTangent:Vector3, tangentGeometryW:Float):Vector3 {
        var result:Vector3 = crossNormalTangent.multiplyScalar(tangentGeometryW);
        return new Vector3(result.x, result.y, result.z);
    }

    static var bitangentGeometry:Vector3 = VaryingNode.varying(getBitangent(NormalNode.normalGeometry.cross(TangentNode.tangentGeometry), TangentNode.tangentGeometry.w)).normalize();
    static var bitangentLocal:Vector3 = VaryingNode.varying(getBitangent(NormalNode.normalLocal.cross(TangentNode.tangentLocal), TangentNode.tangentLocal.w)).normalize();
    static var bitangentView:Vector3 = VaryingNode.varying(getBitangent(NormalNode.normalView.cross(TangentNode.tangentView), TangentNode.tangentView.w)).normalize();
    static var bitangentWorld:Vector3 = VaryingNode.varying(getBitangent(NormalNode.normalWorld.cross(TangentNode.tangentWorld), TangentNode.tangentWorld.w)).normalize();
    static var transformedBitangentView:Vector3 = getBitangent(NormalNode.transformedNormalView.cross(TangentNode.transformedTangentView), TangentNode.transformedTangentView.w).normalize();
    static var transformedBitangentWorld:Vector3 = transformedBitangentView.transformDirection(CameraNode.cameraViewMatrix).normalize();
}