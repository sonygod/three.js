import js.Browser.console;
import js.Node.process;

import haxe.Serializer;
import haxe.Unserializer;

import js.gl.WebGLRenderingContext.*;

class ShaderNode {
	static function vec3(v:Float) return new Float32Array([v, v, v]);
	static function vec3(v1:Float, v2:Float, v3:Float) return new Float32Array([v1, v2, v3]);
}

class OperatorNode {
	static function greaterThan(v1:Float32Array, v2:Float32Array) {
		return v1.map((v, i) -> v > v2[i]);
	}
}

class MathNode {
	static function max(v1:Float32Array, v2:Float32Array) {
		return v1.map((v, i) -> max(v, v2[i]));
	}

	static function pow(v:Float32Array, e:Float) {
		return v.map(v -> Math.pow(v, e));
	}

	static function mix(v1:Float32Array, v2:Float32Array, isAbove:Bool32Array) {
		return v1.map((v, i) -> if (isAbove[i]) v2[i] else v);
	}
}

class MXSRGBTextureToLinRec709 {
	public static function from(color:Float32Array) {
		var colorVar = color.slice();
		var isAbove = OperatorNode.greaterThan(colorVar, ShaderNode.vec3(0.04045));
		var linSeg = MathNode.div(colorVar, 12.92);
		var powSeg = MathNode.pow(MathNode.max(MathNode.div(MathNode.add(colorVar, ShaderNode.vec3(0.055)), 1.055), ShaderNode.vec3(0.0)), 2.4);
		return MathNode.mix(linSeg, powSeg, isAbove);
	}
}

class Layout {
	var name:String;
	var type:String;
	var inputs:Array<Input>;

	public function new(name:String, type:String, inputs:Array<Input>) {
		this.name = name;
		this.type = type;
		this.inputs = inputs;
	}
}

class Input {
	var name:String;
	var type:String;

	public function new(name:String, type:String) {
		this.name = name;
		this.type = type;
	}
}

var layout = new Layout("mx_srgb_texture_to_lin_rec709", "vec3", [new Input("color", "vec3")]);
MXSRGBTextureToLinRec709.setLayout(layout);

class Main {
	static function main() {
		var color = ShaderNode.vec3(0.5, 0.3, 0.8);
		var result = MXSRGBTextureToLinRec709.from(color);
		console.log(result);
	}
}

Main.main();