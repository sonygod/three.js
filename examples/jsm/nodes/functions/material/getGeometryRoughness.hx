package three.js.examples.jsm.nodes.functions.material;

import three.accessors.NormalNode;
import three.shadernode.ShaderNode;

class GetGeometryRoughness {
    public static function getGeometryRoughness():Float {
        var normalGeometry = NormalNode.getInstance();
        var dxy = normalGeometry.dFdx().abs().max(normalGeometry.dFdy().abs());
        var geometryRoughness = dxy.x > dxy.y ? (dxy.x > dxy.z ? dxy.x : dxy.z) : (dxy.y > dxy.z ? dxy.y : dxy.z);
        return geometryRoughness;
    }
}