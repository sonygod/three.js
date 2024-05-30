import LightingModel from '../core/LightingModel.js';
import { diffuseColor } from '../core/PropertyNode.js';
import { float } from '../shadernode/ShaderNode.js';

class ShadowMaskModel extends LightingModel {

	public var shadowNode:Float;

	public function new() {

		super();

		this.shadowNode = float( 1 ).toVar( 'shadowMask' );

	}

	public function direct( shadowMask:Float ) {

		this.shadowNode *= shadowMask;

	}

	public function finish( context:Context ) {

		diffuseColor.a *= this.shadowNode.oneMinus();

		context.outgoingLight.rgb = diffuseColor.rgb; // TODO: Optimize LightsNode to avoid this assignment

	}

}

export default ShadowMaskModel;


Please note that the Haxe code assumes that the `Context` class and its `outgoingLight` property have been defined elsewhere in your code. Also, the `Float` class and its `oneMinus()` method are assumed to be available. If these classes and methods are not available, you will need to define them or use equivalent functionality.

Also, the Haxe code uses the `public` access modifier for the `shadowNode` variable and the `new`, `direct`, and `finish` functions. This is because Haxe does not have a default access modifier like JavaScript, and all members are private by default. If you want to make these members public, you need to explicitly declare them as such.

Finally, the Haxe code uses the `export default` syntax to export the `ShadowMaskModel` class. This is equivalent to the `export default` syntax in JavaScript. If you want to export the class under a different name, you can use the `@:alias` metadata tag. For example:


@:alias("ShadowMaskModel")
class MyShadowMaskModel extends LightingModel {
    // ...
}