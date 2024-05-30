package three.js.examples.jsm.nodes.lighting;

import three.js.nodes.SpotLightNode;
import three.js.accessors.TextureNode;
import three.js.shadernode.ShaderNode;
import three.js.core.Node;
import three.js.lights.IESSpotLight;

class IESSpotLightNode extends SpotLightNode {
    public function new() {
        super();
    }

    override public function getSpotAttenuation(angleCosine:Float):Float {
        var iesMap:TextureNode = cast this.light.iesMap;

        var spotAttenuation:Float = null;

        if (iesMap != null && iesMap.isTexture) {
            var angle:Float = Math.acos(angleCosine) / Math.PI;

            spotAttenuation = TextureNode.texture(iesMap, Vec2.create(angle, 0), 0).r;
        } else {
            spotAttenuation = super.getSpotAttenuation(angleCosine);
        }

        return spotAttenuation;
    }
}

Node.addNodeClass('IESSpotLightNode', IESSpotLightNode);

Node.addLightNode(IESSpotLight, IESSpotLightNode);