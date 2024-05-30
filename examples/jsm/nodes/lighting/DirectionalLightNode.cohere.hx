import AnalyticLightNode from './AnalyticLightNode.hx';
import { lightTargetDirection } from './LightNode.hx';
import { addLightNode } from './LightsNode.hx';
import { addNodeClass } from '../core/Node.hx';

import { DirectionalLight } from 'three';

class DirectionalLightNode extends AnalyticLightNode {
	public function new(light:Dynamic) {
		super(light);
	}

	public function setup(builder:Dynamic) {
		super.setup(builder);

		var lightingModel = builder.context.lightingModel;
		var lightColor = this.colorNode;
		var lightDirection = lightTargetDirection(this.light);
		var reflectedLight = builder.context.reflectedLight;

		lightingModel.direct({ lightDirection, lightColor, reflectedLight, shadowMask: this.shadowMaskNode }, builder.stack, builder);
	}
}

addNodeClass('DirectionalLightNode', DirectionalLightNode);
addLightNode(DirectionalLight, DirectionalLightNode);