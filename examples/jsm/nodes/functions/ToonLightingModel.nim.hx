import LightingModel from '../core/LightingModel.js';
import BRDF_Lambert from './BSDF/BRDF_Lambert.js';
import { diffuseColor } from '../core/PropertyNode.js';
import { normalGeometry } from '../accessors/NormalNode.js';
import { tslFn, float, vec2, vec3 } from '../shadernode/ShaderNode.js';
import { mix, smoothstep } from '../math/MathNode.js';
import { materialReference } from '../accessors/MaterialReferenceNode.js';

var getGradientIrradiance = tslFn( function( data ) {
	var normal = data.normal;
	var lightDirection = data.lightDirection;
	var builder = data.builder;

	// dotNL will be from -1.0 to 1.0
	var dotNL = normal.dot( lightDirection );
	var coord = vec2( dotNL.mul( 0.5 ).add(  0.5 ), 0.0 );

	if ( builder.material.gradientMap ) {

		var gradientMap = materialReference( 'gradientMap', 'texture' ).context( { getUV: function() { return coord; } } );

		return vec3( gradientMap.r );

	} else {

		var fw = coord.fwidth().mul( 0.5 );

		return mix( vec3( 0.7 ), vec3( 1.0 ), smoothstep( float( 0.7 ).sub( fw.x ), float( 0.7 ).add( fw.x ), coord.x ) );

	}
} );

class ToonLightingModel extends LightingModel {

	public function direct( data, stack, builder ) {

		var irradiance = getGradientIrradiance( { normal: normalGeometry, lightDirection: data.lightDirection, builder: builder } ).mul( data.lightColor );

		data.reflectedLight.directDiffuse.addAssign( irradiance.mul( BRDF_Lambert( { diffuseColor: diffuseColor.rgb } ) ) );

	}

	public function indirectDiffuse( data ) {

		data.reflectedLight.indirectDiffuse.addAssign( data.irradiance.mul( BRDF_Lambert( { diffuseColor } ) ) );

	}

}

export default ToonLightingModel;