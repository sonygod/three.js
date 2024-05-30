class NodeShaderStage {
    public static var VERTEX:String = 'vertex';
    public static var FRAGMENT:String = 'fragment';
}

class NodeUpdateType {
    public static var NONE:String = 'none';
    public static var FRAME:String = 'frame';
    public static var RENDER:String = 'render';
    public static var OBJECT:String = 'object';
}

class NodeType {
    public static var BOOLEAN:String = 'bool';
    public static var INTEGER:String = 'int';
    public static var FLOAT:String = 'float';
    public static var VECTOR2:String = 'vec2';
    public static var VECTOR3:String = 'vec3';
    public static var VECTOR4:String = 'vec4';
    public static var MATRIX2:String = 'mat2';
    public static var MATRIX3:String = 'mat3';
    public static var MATRIX4:String = 'mat4';
}

class Constants {
    public static var defaultShaderStages:Array<String> = [ 'fragment', 'vertex' ];
    public static var defaultBuildStages:Array<String> = [ 'setup', 'analyze', 'generate' ];
    public static var shaderStages:Array<String> = [ ...defaultShaderStages, 'compute' ];
    public static var vectorComponents:Array<String> = [ 'x', 'y', 'z', 'w' ];
}