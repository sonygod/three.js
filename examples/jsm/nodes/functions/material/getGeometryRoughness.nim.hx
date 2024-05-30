import three.examples.jsm.accessors.NormalNode;
import three.examples.jsm.shadernode.ShaderNode;

class GetGeometryRoughness {
    public static function main() {
        var normalGeometry = NormalNode.normalGeometry;
        var tslFn = ShaderNode.tslFn;

        var getGeometryRoughness = tslFn(function() {
            var dxy = normalGeometry.dFdx().abs().max(normalGeometry.dFdy().abs());
            var geometryRoughness = dxy.x.max(dxy.y).max(dxy.z);

            return geometryRoughness;
        });

        trace(getGeometryRoughness);
    }
}