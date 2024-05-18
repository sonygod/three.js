package three.js.examples.jsm.nodes.lighting;

import three.js.examples.jsm.nodes.SpotLightNode;
import three.js.examples.jsm.nodes.LightsNode;
import three.js.examples.accessors.TextureNode;
import three.js.examples.shadernode.ShaderNode;
import three.js.core.Node;

import three.lights.IESSpotLight;

class IESSpotLightNode extends SpotLightNode {

    override public function getSpotAttenuation(angleCosine:Float):Float {
        var iesMap:TextureNode = this.light.iesMap;

        var spotAttenuation:Float = null;

        if (iesMap != null && iesMap.isTexture) {
            var angle:Float = Math.acos(angleCosine) / Math.PI;

            spotAttenuation = TextureNode.texture(iesMap, ShaderNode.vec2(angle, 0), 0).r;
        } else {
            spotAttenuation = super.getSpotAttenuation(angleCosine);
        }

        return spotAttenuation;
    }

}

Node.addNodeClass('IESSpotLightNode', IESSpotLightNode);

LightsNode.addLightNode(IESSpotLight, IESSpotLightNode);