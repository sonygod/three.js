import NodeMaterial, { addNodeMaterial } from './NodeMaterial.js';
import { materialReference } from '../accessors/MaterialReferenceNode.js';
import { diffuseColor } from '../core/PropertyNode.js';
import { vec3 } from '../shadernode/ShaderNode.js';
import { MeshMatcapMaterial } from 'three';
import { mix } from '../math/MathNode.js';
import { matcapUV } from '../utils/MatcapUVNode.js';

class MeshMatcapNodeMaterial extends NodeMaterial {

	public var isMeshMatcapNodeMaterial:Bool;
	public var lights:Bool;

	public function new( parameters:Dynamic) {

		super();

		this.isMeshMatcapNodeMaterial = true;

		this.lights = false;

		this.setDefaultValues( new MeshMatcapMaterial() );

		this.setValues( parameters );

	}

	public function setupVariants( builder:Dynamic ) {

		var uv = matcapUV;

		var matcapColor;

		if ( builder.material.matcap ) {

			matcapColor = materialReference( 'matcap', 'texture' ).context( { getUV: function() return uv; } );

		} else {

			matcapColor = vec3( mix( 0.2, 0.8, uv.y ) ); // default if matcap is missing

		}

		diffuseColor.rgb.mulAssign( matcapColor.rgb );

	}

}

addNodeMaterial( 'MeshMatcapNodeMaterial', MeshMatcapNodeMaterial );