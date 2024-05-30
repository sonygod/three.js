import AnalyticLightNode from './AnalyticLightNode.hx';
import { addLightNode } from './LightsNode.hx';
import { addNodeClass } from '../core/Node.hx';

import three.AmbientLight;

class AmbientLightNode extends AnalyticLightNode {

	public function new(light? : AmbientLight) {

		super(light);

	}

	public function setup(context : Dynamic) {

		context.irradiance.addAssign(this.colorNode);

	}

}

extern class AmbientLightNode {

	public static function main() {

		addNodeClass('AmbientLightNode', AmbientLightNode);

		addLightNode(AmbientLight, AmbientLightNode);

	}

}