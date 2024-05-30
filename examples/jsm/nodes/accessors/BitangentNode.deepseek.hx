import three.js.examples.jsm.nodes.core.VaryingNode;
import three.js.examples.jsm.nodes.accessors.CameraNode;
import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.accessors.TangentNode;

function getBitangent(crossNormalTangent:Vec4):Vec3 {
    return crossNormalTangent.mul(tangentGeometry.w).xyz;
}

var bitangentGeometry = VaryingNode.varying(getBitangent(normalGeometry.cross(tangentGeometry))).normalize();
var bitangentLocal = VaryingNode.varying(getBitangent(normalLocal.cross(tangentLocal))).normalize();
var bitangentView = VaryingNode.varying(getBitangent(normalView.cross(tangentView))).normalize();
var bitangentWorld = VaryingNode.varying(getBitangent(normalWorld.cross(tangentWorld))).normalize();
var transformedBitangentView = getBitangent(transformedNormalView.cross(transformedTangentView)).normalize();
var transformedBitangentWorld = transformedBitangentView.transformDirection(cameraViewMatrix).normalize();