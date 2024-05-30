import TempNode from '../core/TempNode.js';
import { mix } from '../math/MathNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, tslFn, nodeObject, nodeProxy, vec4 } from '../shadernode/ShaderNode.js';

import LinearSRGBColorSpace from 'three/src/constants.js';
import SRGBColorSpace from 'three/src/constants.js';

var sRGBToLinearShader = tslFn( ( inputs ) -> {

	var { value } = inputs;
	var { rgb } = value;

	var a = rgb.mul( 0.9478672986 ).add( 0.0521327014 ).pow( 2.4 );
	var b = rgb.mul( 0.0773993808 );
	var factor = rgb.lessThanEqual( 0.04045 );

	var rgbResult = mix( a, b, factor );

	return vec4( rgbResult, value.a );

} );

var LinearTosRGBShader = tslFn( ( inputs ) -> {

	var { value } = inputs;
	var { rgb } = value;

	var a = rgb.pow( 0.41666 ).mul( 1.055 ).sub( 0.055 );
	var b = rgb.mul( 12.92 );
	var factor = rgb.lessThanEqual( 0.0031308 );

	var rgbResult = mix( a, b, factor );

	return vec4( rgbResult, value.a );

} );

var getColorSpaceMethod = ( colorSpace ) -> {

	var method = null;

	if ( colorSpace == LinearSRGBColorSpace ) {

		method = 'Linear';

	} else if ( colorSpace == SRGBColorSpace ) {

		method = 'sRGB';

	}

	return method;

};

var getMethod = ( source, target ) -> {

	return getColorSpaceMethod( source ) + 'To' + getColorSpaceMethod( target );

};

class ColorSpaceNode extends TempNode {

	public var method:String;
	public var node:Dynamic;

	public function new( method:String, node:Dynamic ) {

		super( 'vec4' );

		this.method = method;
		this.node = node;

	}

	public function setup() {

		var { method, node } = this;

		if ( method == ColorSpaceNode.LINEAR_TO_LINEAR )
			return node;

		return Methods[ method ]( { value: node } );

	}

}

ColorSpaceNode.LINEAR_TO_LINEAR = 'LinearToLinear';
ColorSpaceNode.LINEAR_TO_sRGB = 'LinearTosRGB';
ColorSpaceNode.sRGB_TO_LINEAR = 'sRGBToLinear';

var Methods = {
	[ ColorSpaceNode.LINEAR_TO_sRGB ]: LinearTosRGBShader,
	[ ColorSpaceNode.sRGB_TO_LINEAR ]: sRGBToLinearShader
};

export default ColorSpaceNode;

export var linearToColorSpace = ( node:Dynamic, colorSpace:Dynamic ) -> nodeObject( new ColorSpaceNode( getMethod( LinearSRGBColorSpace, colorSpace ), nodeObject( node ) ) );
export var colorSpaceToLinear = ( node:Dynamic, colorSpace:Dynamic ) -> nodeObject( new ColorSpaceNode( getMethod( colorSpace, LinearSRGBColorSpace ), nodeObject( node ) ) );

export var linearTosRGB = nodeProxy( ColorSpaceNode, ColorSpaceNode.LINEAR_TO_sRGB );
export var sRGBToLinear = nodeProxy( ColorSpaceNode, ColorSpaceNode.sRGB_TO_LINEAR );

addNodeElement( 'linearTosRGB', linearTosRGB );
addNodeElement( 'sRGBToLinear', sRGBToLinear );
addNodeElement( 'linearToColorSpace', linearToColorSpace );
addNodeElement( 'colorSpaceToLinear', colorSpaceToLinear );

addNodeClass( 'ColorSpaceNode', ColorSpaceNode );