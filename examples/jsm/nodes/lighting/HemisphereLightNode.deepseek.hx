import three.AnalyticLightNode;
import three.LightsNode.addLightNode;
import three.UniformNode.uniform;
import three.MathNode.mix;
import three.NormalNode.normalView;
import three.Object3DNode.objectPosition;
import three.Node.addNodeClass;

import three.Color;
import three.HemisphereLight;

class HemisphereLightNode extends AnalyticLightNode {

	public function new(light:HemisphereLight = null) {

		super(light);

		this.lightPositionNode = objectPosition(light);
		this.lightDirectionNode = this.lightPositionNode.normalize();

		this.groundColorNode = uniform(new Color());

	}

	public function update(frame:Dynamic) {

		var light = this.light;

		super.update(frame);

		this.lightPositionNode.object3d = light;

		this.groundColorNode.value.copy(light.groundColor).multiplyScalar(light.intensity);

	}

	public function setup(builder:Dynamic) {

		var colorNode = this.colorNode;
		var groundColorNode = this.groundColorNode;
		var lightDirectionNode = this.lightDirectionNode;

		var dotNL = normalView.dot(lightDirectionNode);
		var hemiDiffuseWeight = dotNL.mul(0.5).add(0.5);

		var irradiance = mix(groundColorNode, colorNode, hemiDiffuseWeight);

		builder.context.irradiance.addAssign(irradiance);

	}

}

addNodeClass('HemisphereLightNode', HemisphereLightNode);

addLightNode(HemisphereLight, HemisphereLightNode);