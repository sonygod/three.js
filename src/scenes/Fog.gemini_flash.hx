package;

import haxe.extern.EitherType;
import js.three.Color;

@:jsRequire("three", "Fog")
extern class Fog {
	function new(color: EitherType<Int, Color>, near: Float, far: Float): Void;
	var isFog: Bool;
	var name: String;
	var color: Color;
	var near: Float;
	var far: Float;

	function clone(): Fog;
	function toJSON(meta: Dynamic): {
		@property type: String;
		@property name: String;
		@property color: Int;
		@property near: Float;
		@property far: Float;
	};
}