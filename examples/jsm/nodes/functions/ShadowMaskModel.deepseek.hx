import LightingModel from '../core/LightingModel.js';
import { diffuseColor } from '../core/PropertyNode.js';
import { float } from '../shadernode/ShaderNode.js';

class ShadowMaskModel extends LightingModel {

	var shadowNode:Float;

	public function new() {

		super();

		this.shadowNode = float( 1 ).toVar( 'shadowMask' );

	}

	public function direct( shadowMask:Float ) {

		this.shadowNode.mulAssign( shadowMask );

	}

	public function finish( context:Context ) {

		diffuseColor.a.mulAssign( this.shadowNode.oneMinus() );

		context.outgoingLight.rgb.assign( diffuseColor.rgb ); // TODO: Optimize LightsNode to avoid this assignment

	}

}

typedef Context = {
	var outgoingLight:{ rgb:Float, a:Float };
}

typedef Float = {
	public function mulAssign(value:Float):Void;
	public function oneMinus():Float;
	public function assign(value:Float):Void;
}

typedef PropertyNode = {
	var a:Float;
	var rgb:Float;
}

typedef ShaderNode = {
	public static function float(value:Float):Float;
}

typedef LightingModel = {
	public function new():Void;
}