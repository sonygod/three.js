import AnalyticLightNode from './AnalyticLightNode.hx';
import { lightTargetDirection } from './LightNode.hx';
import { addLightNode } from './LightsNode.hx';
import { getDistanceAttenuation } from './LightUtils.hx';
import { uniform } from '../core/UniformNode.hx';
import { smoothstep } from '../math/MathNode.hx';
import { objectViewPosition } from '../accessors/Object3DNode.hx';
import { positionView } from '../accessors/PositionNode.hx';
import { addNodeClass } from '../core/Node.hx';

import three.SpotLight;

class SpotLightNode extends AnalyticLightNode {

	public var coneCosNode:UniformNode<Float>;
	public var penumbraCosNode:UniformNode<Float>;

	public var cutoffDistanceNode:UniformNode<Float>;
	public var decayExponentNode:UniformNode<Float>;

	public function new( light:Null<SpotLight> ) {

		super( light );

		this.coneCosNode = uniform( 0 );
		this.penumbraCosNode = uniform( 0 );

		this.cutoffDistanceNode = uniform( 0 );
		this.decayExponentNode = uniform( 0 );

	}

	public function update( frame:Dynamic ) {

		super.update( frame );

		const light = this.light;

		this.coneCosNode.value = Math.cos( light.angle );
		this.penumbraCosNode.value = Math.cos( light.angle * ( 1 - light.penumbra ) );

		this.cutoffDistanceNode.value = light.distance;
		this.decayExponentNode.value = light.decay;

	}

	public function getSpotAttenuation( angleCosine:Float ) {

		const { coneCosNode, penumbraCosNode } = this;

		return smoothstep( coneCosNode, penumbraCosNode, angleCosine );

	}

	public function setup( builder:Dynamic ) {

		super.setup( builder );

		const lightingModel = builder.context.lightingModel;

		const { colorNode, cutoffDistanceNode, decayExponentNode, light } = this;

		const lVector = objectViewPosition( light ).sub( positionView ); // @TODO: Add it into LightNode

		const lightDirection = lVector.normalize();
		const angleCos = lightDirection.dot( lightTargetDirection( light ) );
		const spotAttenuation = this.getSpotAttenuation( angleCos );

		const lightDistance = lVector.length();

		const lightAttenuation = getDistanceAttenuation( {
			lightDistance,
			cutoffDistance: cutoffDistanceNode,
			decayExponent: decayExponentNode
		} );

		const lightColor = colorNode.mul( spotAttenuation ).mul( lightAttenuation );

		const reflectedLight = builder.context.reflectedLight;

		lightingModel.direct( {
			lightDirection,
			lightColor,
			reflectedLight,
			shadowMask: this.shadowMaskNode
		}, builder.stack, builder );

	}

}

export default SpotLightNode;

addNodeClass( 'SpotLightNode', SpotLightNode );

addLightNode( SpotLight, SpotLightNode );