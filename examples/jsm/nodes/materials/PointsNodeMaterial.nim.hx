import NodeMaterial, { addNodeMaterial } from './NodeMaterial.js';

import PointsMaterial from 'three.js/src/materials/PointsMaterial.js';

class DefaultValues extends PointsMaterial {}

class PointsNodeMaterial extends NodeMaterial {

	public var isPointsNodeMaterial:Bool = true;
	public var lights:Bool = false;
	public var normals:Bool = false;
	public var transparent:Bool = true;
	public var sizeNode:Null<Dynamic> = null;

	public function new( parameters:Dynamic ) {

		super();

		this.setDefaultValues( new DefaultValues() );

		this.setValues( parameters );

	}

	public function copy( source:PointsNodeMaterial ):PointsNodeMaterial {

		this.sizeNode = source.sizeNode;

		return super.copy( source );

	}

}

addNodeMaterial( 'PointsNodeMaterial', PointsNodeMaterial );