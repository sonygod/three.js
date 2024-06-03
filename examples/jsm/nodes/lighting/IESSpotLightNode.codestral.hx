@:import("./SpotLightNode.hx")
@:import("./LightsNode.hx")
@:import("../accessors/TextureNode.hx")
@:import("../shadernode/ShaderNode.hx")
@:import("../core/Node.hx")
@:import("../../lights/IESSpotLight.hx")

class IESSpotLightNode extends SpotLightNode {

    public function getSpotAttenuation(angleCosine:Float):Dynamic {
        var iesMap = this.light.iesMap;
        var spotAttenuation:Dynamic = null;

        if (iesMap != null && iesMap.isTexture) {
            var angle = angleCosine.acos() * (1.0 / Math.PI);
            spotAttenuation = texture(iesMap, vec2(angle, 0), 0).r;
        } else {
            spotAttenuation = super.getSpotAttenuation(angleCosine);
        }

        return spotAttenuation;
    }
}

@:export
class IESSpotLightNodeExport {
    public static function main() {
        addNodeClass("IESSpotLightNode", IESSpotLightNode);
        addLightNode(IESSpotLight, IESSpotLightNode);
    }
}