import js.normalGeometry from '../../accessors/NormalNode.js' as NormalNode;
import js.tslFn from '../../shadernode/ShaderNode.js';

function getGeometryRoughness() {
    var dxy = js.NormalNode.normalGeometry.dFdx().abs().max(js.NormalNode.normalGeometry.dFdy().abs());
    var geometryRoughness = dxy.x.max(dxy.y).max(dxy.z);
    return geometryRoughness;
}

@:jsExport("default")
class GetGeometryRoughness {
    static var geometryRoughness = getGeometryRoughness();
}