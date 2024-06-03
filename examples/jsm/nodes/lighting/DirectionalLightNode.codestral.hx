import AnalyticLightNode from './AnalyticLightNode';
import { lightTargetDirection } from './LightNode';
import { addLightNode } from './LightsNode';
import { addNodeClass } from '../core/Node';
import { DirectionalLight } from 'three';

class DirectionalLightNode extends AnalyticLightNode {

	public function new(light:DirectionalLight = null) {
		super(light);
	}

	public function setup(builder:Builder) {
		super.setup(builder);

		var lightingModel = builder.context.lightingModel;
		var lightColor = this.colorNode;
		var lightDirection = lightTargetDirection(this.light);
		var reflectedLight = builder.context.reflectedLight;

		lightingModel.direct({
			lightDirection: lightDirection,
			lightColor: lightColor,
			reflectedLight: reflectedLight,
			shadowMask: this.shadowMaskNode
		}, builder.stack, builder);
	}

}

addNodeClass('DirectionalLightNode', DirectionalLightNode);
addLightNode(DirectionalLight, DirectionalLightNode);