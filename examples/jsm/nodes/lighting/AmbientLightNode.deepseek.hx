import three.js.examples.jsm.nodes.lighting.AnalyticLightNode;
import three.js.examples.jsm.nodes.lighting.LightsNode.addLightNode;
import three.js.examples.jsm.nodes.core.Node.addNodeClass;

import three.js.AmbientLight;

class AmbientLightNode extends AnalyticLightNode {

	public function new(light:AmbientLight = null) {
		super(light);
	}

	public function setup(context:Dynamic) {
		context.irradiance.addAssign(this.colorNode);
	}

}

addNodeClass('AmbientLightNode', AmbientLightNode);

addLightNode(AmbientLight, AmbientLightNode);