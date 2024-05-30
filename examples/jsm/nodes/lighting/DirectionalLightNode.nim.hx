import AnalyticLightNode from './AnalyticLightNode.hx';
import { lightTargetDirection } from './LightNode.hx';
import { addLightNode } from './LightsNode.hx';
import { addNodeClass } from '../core/Node.hx';

import three.lights.DirectionalLight;

class DirectionalLightNode extends AnalyticLightNode {

	public function new( light : Null<DirectionalLight> ) {

		super( light );

	}

	public function setup( builder : NodeBuilder ) {

		super.setup( builder );

		const lightingModel = builder.context.lightingModel;

		const lightColor = this.colorNode;
		const lightDirection = lightTargetDirection( this.light );
		const reflectedLight = builder.context.reflectedLight;

		lightingModel.direct( {
			lightDirection,
			lightColor,
			reflectedLight,
			shadowMask: this.shadowMaskNode
		}, builder.stack, builder );

	}

}

export default DirectionalLightNode;

addNodeClass( 'DirectionalLightNode', DirectionalLightNode );

addLightNode( DirectionalLight, DirectionalLightNode );