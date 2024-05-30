import SpotLightNode from './SpotLightNode.js';
import { addLightNode } from './LightsNode.js';
import { texture } from '../accessors/TextureNode.js';
import { vec2 } from '../shadernode/ShaderNode.js';
import { addNodeClass } from '../core/Node.js';

import IESSpotLight from '../../lights/IESSpotLight.js';

class IESSpotLightNode extends SpotLightNode {

	public function getSpotAttenuation( angleCosine ) {

		const iesMap = this.light.iesMap;

		var spotAttenuation = null;

		if ( iesMap != null && iesMap.isTexture == true ) {

			const angle = angleCosine.acos().mul( 1.0 / Math.PI );

			spotAttenuation = texture( iesMap, vec2( angle, 0 ), 0 ).r;

		} else {

			spotAttenuation = super.getSpotAttenuation( angleCosine );

		}

		return spotAttenuation;

	}

}

@:build(macro $v{@:expose('IESSpotLightNode')} IESSpotLightNode)
extern class IESSpotLightNode extends SpotLightNode {

	public function new() {
		super();
	}

	public function getSpotAttenuation( angleCosine ) {
		return null;
	}

}

addNodeClass( 'IESSpotLightNode', IESSpotLightNode );

addLightNode( IESSpotLight, IESSpotLightNode );