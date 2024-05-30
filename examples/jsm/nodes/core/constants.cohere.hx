package;

@:enum("vertex fragment")
extern enum NodeShaderStage {
	VERTEX,
	FRAGMENT,
}

@:enum("none frame render object")
extern enum NodeUpdateType {
	NONE,
	FRAME,
	RENDER,
	OBJECT,
}

@:enum("bool int float vec2 vec3 vec4 mat2 mat3 mat4")
extern enum NodeType {
	BOOLEAN,
	INTEGER,
	FLOAT,
	VECTOR2,
	VECTOR3,
	VECTOR4,
	MATRIX2,
	MATRIX3,
	MATRIX4,
}

@:arrayAccess
class DefaultShaderStages {
	static var values = [ 'fragment', 'vertex' ];
}

@:arrayAccess
class DefaultBuildStages {
	static var values = [ 'setup', 'analyze', 'generate' ];
}

@:arrayAccess
class ShaderStages {
	static var values = [ ...DefaultShaderStages.values, 'compute' ];
}

@:arrayAccess
class VectorComponents {
	static var values = [ 'x', 'y', 'z', 'w' ];
}