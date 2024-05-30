package three.examples.jsm.nodes.core;

@:enum abstract NodeShaderStage {
	VERTEX('vertex'),
	FRAGMENT('fragment');

	public var value:String;

	public function new(value:String) {
		this.value = value;
	}
}

@:enum abstract NodeUpdateType {
	NONE('none'),
	FRAME('frame'),
	RENDER('render'),
	OBJECT('object');

	public var value:String;

	public function new(value:String) {
		this.value = value;
	}
}

@:enum abstract NodeType {
	BOOLEAN('bool'),
	INTEGER('int'),
	FLOAT('float'),
	VECTOR2('vec2'),
	VECTOR3('vec3'),
	VECTOR4('vec4'),
	MATRIX2('mat2'),
	MATRIX3('mat3'),
	MATRIX4('mat4');

	public var value:String;

	public function new(value:String) {
		this.value = value;
	}
}

class Constants {
	public static var defaultShaderStages:Array<String> = ['fragment', 'vertex'];
	public static var defaultBuildStages:Array<String> = ['setup', 'analyze', 'generate'];
	public static var shaderStages:Array<String> = defaultShaderStages.concat(['compute']);
	public static var vectorComponents:Array<String> = ['x', 'y', 'z', 'w'];
}