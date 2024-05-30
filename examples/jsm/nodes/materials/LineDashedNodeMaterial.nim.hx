import NodeMaterial, { addNodeMaterial } from './NodeMaterial.js';
import { attribute } from '../core/AttributeNode.js';
import { varying } from '../core/VaryingNode.js';
import { materialLineDashSize, materialLineGapSize, materialLineScale } from '../accessors/MaterialNode.js';
import { dashSize, gapSize } from '../core/PropertyNode.js';
import { float } from '../shadernode/ShaderNode.js';
import LineDashedMaterial from 'three';

class DefaultValues extends LineDashedMaterial {}
var defaultValues = new DefaultValues();

class LineDashedNodeMaterial extends NodeMaterial {

	public var isLineDashedNodeMaterial:Bool = true;
	public var lights:Bool = false;
	public var normals:Bool = false;

	public var offsetNode:Null<Dynamic>;
	public var dashScaleNode:Null<Dynamic>;
	public var dashSizeNode:Null<Dynamic>;
	public var gapSizeNode:Null<Dynamic>;

	public function new( parameters:Dynamic ) {

		super();

		this.setDefaultValues( defaultValues );

		this.offsetNode = null;
		this.dashScaleNode = null;
		this.dashSizeNode = null;
		this.gapSizeNode = null;

		this.setValues( parameters );

	}

	public function setupVariants() {

		var offsetNode = this.offsetNode;
		var dashScaleNode = this.dashScaleNode ? float( this.dashScaleNode ) : materialLineScale;
		var dashSizeNode = this.dashSizeNode ? float( this.dashSizeNode ) : materialLineDashSize;
		var gapSizeNode = this.dashSizeNode ? float( this.dashGapNode ) : materialLineGapSize;

		dashSize.assign( dashSizeNode );
		gapSize.assign( gapSizeNode );

		var vLineDistance = varying( attribute( 'lineDistance' ).mul( dashScaleNode ) );
		var vLineDistanceOffset = offsetNode ? vLineDistance.add( offsetNode ) : vLineDistance;

		vLineDistanceOffset.mod( dashSize.add( gapSize ) ).greaterThan( dashSize ).discard();

	}

}

export default LineDashedNodeMaterial;

addNodeMaterial( 'LineDashedNodeMaterial', LineDashedNodeMaterial );