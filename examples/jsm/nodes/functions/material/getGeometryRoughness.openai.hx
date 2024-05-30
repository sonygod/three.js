package three.js.examples.jsm.nodes.functions.material;

import three.js.accessors.NormalNode;
import three.js.shadernode.ShaderNode;

class GetGeometryRoughness {
  public static var getGeometryRoughness = ShaderNode.tslFn(function() {
    var normalGeometry = NormalNode.normalGeometry;
    var dxy = normalGeometry.dFdx().abs().max(normalGeometry.dFdy().abs());
    var geometryRoughness = dxy.x.max(dxy.y).max(dxy.z);
    return geometryRoughness;
  });
}