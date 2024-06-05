import core.VaryingNode;
import nodes.CameraNode;
import nodes.NormalNode;
import nodes.TangentNode;

class BitangentNode {

  public static function getBitangent( crossNormalTangent : VaryingNode.Vec4 ) : VaryingNode.Vec3 {
    return crossNormalTangent.mul(TangentNode.tangentGeometry.w).xyz;
  }

  public static var bitangentGeometry : VaryingNode.Vec3 = VaryingNode.varying(getBitangent(NormalNode.normalGeometry.cross(TangentNode.tangentGeometry))).normalize();
  public static var bitangentLocal : VaryingNode.Vec3 = VaryingNode.varying(getBitangent(NormalNode.normalLocal.cross(TangentNode.tangentLocal))).normalize();
  public static var bitangentView : VaryingNode.Vec3 = VaryingNode.varying(getBitangent(NormalNode.normalView.cross(TangentNode.tangentView))).normalize();
  public static var bitangentWorld : VaryingNode.Vec3 = VaryingNode.varying(getBitangent(NormalNode.normalWorld.cross(TangentNode.tangentWorld))).normalize();
  public static var transformedBitangentView : VaryingNode.Vec3 = getBitangent(NormalNode.transformedNormalView.cross(TangentNode.transformedTangentView)).normalize();
  public static var transformedBitangentWorld : VaryingNode.Vec3 = transformedBitangentView.transformDirection(CameraNode.cameraViewMatrix).normalize();

}