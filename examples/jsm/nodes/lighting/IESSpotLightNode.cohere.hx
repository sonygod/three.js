import SpotLightNode from './SpotLightNode.hx';
import { addLightNode } from './LightsNode.hx';
import { $texture } from '../accessors/TextureNode.hx';
import { $vec2 } from '../shadernode/ShaderNode.hx';
import { addNodeClass } from '../core/Node.hx';

import IESSpotLight from '../../lights/IESSpotLight.hx';

class IESSpotLightNode extends SpotLightNode {

	public function getSpotAttenuation(angleCosine:Float):Float {

		var iesMap = light.iesMap;

		var spotAttenuation:Float = null;

		if (iesMap != null && iesMap.isTexture) {

			var angle = angleCosine.acos() * (1.0 / Math.PI);

			spotAttenuation = $texture(iesMap, $vec2(angle, 0)).r;

		} else {

			spotAttenu.super = super.getSpotAttenuation(angleCosine);

		}

		return spotAttenuation;

	}

}

@:build(IESSpotLightNode_build)
class IESSpotLightNode_build {
	public static function build(cmp:IESSpotLightNode):IESSpotLightNode {
		return new IESSpotLightNode();
	}
}

@:build(default)
class export {
	public static function build():IESSpotLightNode {
		return new IESSpotLightNode();
	}
}

addNodeClass('IESSpotLightNode', IESSpotLightNode);

addLightNode(IESSpotLight, IESSpotLightNode);