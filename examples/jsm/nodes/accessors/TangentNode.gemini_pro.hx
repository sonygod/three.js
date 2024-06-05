import attribute from "../core/AttributeNode.hx";
import varying from "../core/VaryingNode.hx";
import cameraViewMatrix from "./CameraNode.hx";
import modelViewMatrix from "./ModelNode.hx";
import {tslFn, vec4} from "../shadernode/ShaderNode.hx";

class TangentGeometry extends ShaderNode {
  public function new() {
    super();
  }

  override function generate(stack:ShaderNodeStack, builder:ShaderNodeBuilder) {
    if (!builder.geometry.hasAttribute("tangent")) {
      builder.geometry.computeTangents();
    }
    return attribute("tangent", "vec4");
  }
}

var tangentGeometry = new TangentGeometry();

var tangentLocal = varying(tangentGeometry.xyz, "tangentLocal");
var tangentView = varying(modelViewMatrix.mul(vec4(tangentLocal, 0)).xyz, "tangentView").normalize();
var tangentWorld = varying(tangentView.transformDirection(cameraViewMatrix), "tangentWorld").normalize();
var transformedTangentView = tangentView.toVar("transformedTangentView");
var transformedTangentWorld = transformedTangentView.transformDirection(cameraViewMatrix).normalize();