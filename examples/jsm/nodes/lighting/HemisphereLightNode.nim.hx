import AnalyticLightNode from './AnalyticLightNode.hx';
import { addLightNode } from './LightsNode.hx';
import { uniform } from '../core/UniformNode.hx';
import { mix } from '../math/MathNode.hx';
import { normalView } from '../accessors/NormalNode.hx';
import { objectPosition } from '../accessors/Object3DNode.hx';
import { addNodeClass } from '../core/Node.hx';

import { Color, HemisphereLight } from 'three';

class HemisphereLightNode extends AnalyticLightNode {

	public var lightPositionNode:ObjectPositionNode;
	public var lightDirectionNode:NormalNode;
	public var groundColorNode:UniformNode;

	public function new( light:HemisphereLight = null ) {

		super( light );

		this.lightPositionNode = objectPosition( light );
		this.lightDirectionNode = this.lightPositionNode.normalize();

		this.groundColorNode = uniform( new Color() );

	}

	public function update( frame:Frame ) {

		const light = this.light;

		super.update( frame );

		this.lightPositionNode.object3d = light;

		this.groundColorNode.value.copy( light.groundColor ).multiplyScalar( light.intensity );

	}

	public function setup( builder:Builder ) {

		const colorNode = this.colorNode;
		const groundColorNode = this.groundColorNode;
		const lightDirectionNode = this.lightDirectionNode;

		const dotNL = normalView.dot( lightDirectionNode );
		const hemiDiffuseWeight = dotNL.mul( 0.5 ).add( 0.5 );

		const irradiance = mix( groundColorNode, colorNode, hemiDiffuseWeight );

		builder.context.irradiance.addAssign( irradiance );

	}

}

export default HemisphereLightNode;

addNodeClass( 'HemisphereLightNode', HemisphereLightNode );

addLightNode( HemisphereLight, HemisphereLightNode );