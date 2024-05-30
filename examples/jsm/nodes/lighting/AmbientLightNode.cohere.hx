import AnalyticLightNode from './AnalyticLightNode.hx';
import { addLightNode } from './LightsNode.hx';
import { addNodeClass } from '../core/Node.hx';

import { AmbientLight } from 'three';

class AmbientLightNode extends AnalyticLightNode {

	public function new( light : AmbientLight = null ) {

		super( light );

	}

	public function setup( { context } : { context : AmbientLightNode } ) {

		context.irradiance.addAssign( this.colorNode );

	}

}

addNodeClass( 'AmbientLightNode', AmbientLightNode );

addLightNode( AmbientLight, AmbientLightNode );