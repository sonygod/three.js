import SpotLightNode from './SpotLightNode.hx';
import LightsNode.addLightNode;
import TextureNode.texture;
import ShaderNode.vec2;
import Node.addNodeClass;

import IESSpotLight from '../../lights/IESSpotLight.hx';

class IESSpotLightNode extends SpotLightNode {

	public function getSpotAttenuation(angleCosine:Float):Float {

		var iesMap = this.light.iesMap;

		var spotAttenuation:Float = null;

		if (iesMap != null && iesMap.isTexture == true) {

			var angle:Float = Math.acos(angleCosine) / Math.PI;

			spotAttenuation = texture(iesMap, vec2(angle, 0), 0).r;

		} else {

			spotAttenuation = super.getSpotAttenuation(angleCosine);

		}

		return spotAttenuation;

	}

}

addNodeClass('IESSpotLightNode', IESSpotLightNode);

addLightNode(IESSpotLight, IESSpotLightNode);