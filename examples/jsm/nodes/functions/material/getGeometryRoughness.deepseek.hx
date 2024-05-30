import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class GetGeometryRoughness {

    static function getGeometryRoughness():ShaderNode {

        var dxy = NormalNode.normalGeometry.dFdx().abs().max( NormalNode.normalGeometry.dFdy().abs() );
        var geometryRoughness = dxy.x.max( dxy.y ).max( dxy.z );

        return geometryRoughness;

    }

}