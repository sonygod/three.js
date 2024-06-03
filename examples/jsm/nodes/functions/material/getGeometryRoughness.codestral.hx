import threehx.nodes.accessors.NormalNode;
import threehx.nodes.shadernode.ShaderNode;

class GetGeometryRoughness {
    static function getGeometryRoughness(): Float {
        var dxy = NormalNode.normalGeometry.dFdx().abs().max(NormalNode.normalGeometry.dFdy().abs());
        var geometryRoughness = dxy.x.max(dxy.y).max(dxy.z);

        return geometryRoughness;
    }
}

class Main {
    static function main() {
        var roughness = GetGeometryRoughness.getGeometryRoughness();
        // Use roughness as needed
    }
}