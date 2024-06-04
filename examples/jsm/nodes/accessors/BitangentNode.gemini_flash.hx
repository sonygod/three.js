import varying from "../core/VaryingNode";
import cameraViewMatrix from "./CameraNode";
import { normalGeometry, normalLocal, normalView, normalWorld, transformedNormalView } from "./NormalNode";
import { tangentGeometry, tangentLocal, tangentView, tangentWorld, transformedTangentView } from "./TangentNode";

function getBitangent(crossNormalTangent) {
  return crossNormalTangent.mul(tangentGeometry.w).xyz;
}

export var bitangentGeometry = varying(getBitangent(normalGeometry.cross(tangentGeometry))).normalize();
export var bitangentLocal = varying(getBitangent(normalLocal.cross(tangentLocal))).normalize();
export var bitangentView = varying(getBitangent(normalView.cross(tangentView))).normalize();
export var bitangentWorld = varying(getBitangent(normalWorld.cross(tangentWorld))).normalize();
export var transformedBitangentView = getBitangent(transformedNormalView.cross(transformedTangentView)).normalize();
export var transformedBitangentWorld = transformedBitangentView.transformDirection(cameraViewMatrix).normalize();