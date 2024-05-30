import three.examples.jsm.nodes.core.TempNode;
import three.examples.jsm.nodes.math.MathNode.mix;
import three.examples.jsm.nodes.core.Node.addNodeClass;
import three.examples.jsm.nodes.shadernode.ShaderNode.addNodeElement;
import three.examples.jsm.nodes.shadernode.ShaderNode.tslFn;
import three.examples.jsm.nodes.shadernode.ShaderNode.nodeObject;
import three.examples.jsm.nodes.shadernode.ShaderNode.nodeProxy;
import three.examples.jsm.nodes.shadernode.ShaderNode.vec4;

import three.LinearSRGBColorSpace;
import three.SRGBColorSpace;

var sRGBToLinearShader = tslFn( ( inputs ) -> {

	var value = inputs.value;
	var rgb = value.rgb;

	var a = rgb.mul( 0.9478672986 ).add( 0.0521327014 ).pow( 2.4 );
	var b = rgb.mul( 0.0773993808 );
	var factor = rgb.lessThanEqual( 0.04045 );

	var rgbResult = mix( a, b, factor );

	return vec4( rgbResult, value.a );

} );

var LinearTosRGBShader = tslFn( ( inputs ) -> {

	var value = inputs.value;
	var rgb = value.rgb;

	var a = rgb.pow( 0.41666 ).mul( 1.055 ).sub( 0.055 );
	var b = rgb.mul( 12.92 );
	var factor = rgb.lessThanEqual( 0.0031308 );

	var rgbResult = mix( a, b, factor );

	return vec4( rgbResult, value.a );

} );

var getColorSpaceMethod = ( colorSpace ) -> {

	var method = null;

	if ( colorSpace === LinearSRGBColorSpace ) {

		method = 'Linear';

	} else if ( colorSpace === SRGBColorSpace ) {

		method = 'sRGB';

	}

	return method;

};

var getMethod = ( source, target ) -> {

	return getColorSpaceMethod( source ) + 'To' + getColorSpaceMethod( target );

};

class ColorSpaceNode extends TempNode {

	public function new(method, node) {

		super('vec4');

		this.method = method;
		this.node = node;

	}

	public function setup() {

		var method = this.method;
		var node = this.node;

		if (method === ColorSpaceNode.LINEAR_TO_LINEAR)
			return node;

		return Methods[method]({value: node});

	}

}

ColorSpaceNode.LINEAR_TO_LINEAR = 'LinearToLinear';
ColorSpaceNode.LINEAR_TO_sRGB = 'LinearTosRGB';
ColorSpaceNode.sRGB_TO_LINEAR = 'sRGBToLinear';

var Methods = {
	ColorSpaceNode.LINEAR_TO_sRGB: LinearTosRGBShader,
	ColorSpaceNode.sRGB_TO_LINEAR: sRGBToLinearShader
};

class ColorSpaceNode extends TempNode {

	public function new(method, node) {

		super('vec4');

		this.method = method;
		this.node = node;

	}

	public function setup() {

		var method = this.method;
		var node = this.node;

		if (method === ColorSpaceNode.LINEAR_TO_LINEAR)
			return node;

		return Methods[method]({value: node});

	}

}

var linearToColorSpace = (node, colorSpace) -> nodeObject(new ColorSpaceNode(getMethod(LinearSRGBColorSpace, colorSpace), nodeObject(node)));
var colorSpaceToLinear = (node, colorSpace) -> nodeObject(new ColorSpaceNode(getMethod(colorSpace, LinearSRGBColorSpace), nodeObject(node)));

var linearTosRGB = nodeProxy(ColorSpaceNode, ColorSpaceNode.LINEAR_TO_sRGB);
var sRGBToLinear = nodeProxy(ColorSpaceNode, ColorSpaceNode.sRGB_TO_LINEAR);

addNodeElement('linearTosRGB', linearTosRGB);
addNodeElement('sRGBToLinear', sRGBToLinear);
addNodeElement('linearToColorSpace', linearToColorSpace);
addNodeElement('colorSpaceToLinear', colorSpaceToLinear);

addNodeClass('ColorSpaceNode', ColorSpaceNode);