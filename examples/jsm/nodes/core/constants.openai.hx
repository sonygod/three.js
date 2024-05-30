package three.js.nodes.core;

class Constants {
    public static inline var NodeShaderStage = {
        VERTEX: 'vertex',
        FRAGMENT: 'fragment'
    };

    public static inline var NodeUpdateType = {
        NONE: 'none',
        FRAME: 'frame',
        RENDER: 'render',
        OBJECT: 'object'
    };

    public static inline var NodeType = {
        BOOLEAN: 'bool',
        INTEGER: 'int',
        FLOAT: 'float',
        VECTOR2: 'vec2',
        VECTOR3: 'vec3',
        VECTOR4: 'vec4',
        MATRIX2: 'mat2',
        MATRIX3: 'mat3',
        MATRIX4: 'mat4'
    };

    public static var defaultShaderStages = ['fragment', 'vertex'];
    public static var defaultBuildStages = ['setup', 'analyze', 'generate'];
    public static var shaderStages = defaultShaderStages.copy().concat(['compute']);
    public static var vectorComponents = ['x', 'y', 'z', 'w'];
}