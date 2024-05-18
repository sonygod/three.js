package three.js.examples.jm.nodes.core;

enum NodeShaderStage {
    VERTEX;
    FRAGMENT;
}

enum NodeUpdateType {
    NONE;
    FRAME;
    RENDER;
    OBJECT;
}

enum NodeType {
    BOOLEAN;
    INTEGER;
    FLOAT;
    VECTOR2;
    VECTOR3;
    VECTOR4;
    MATRIX2;
    MATRIX3;
    MATRIX4;
}

class Constants {
    public static var defaultShaderStages:Array<String> = [ 'fragment', 'vertex' ];
    public static var defaultBuildStages:Array<String> = [ 'setup', 'analyze', 'generate' ];
    public static var shaderStages:Array<String> = defaultShaderStages.copy();
    shaderStages.push('compute');

    public static var vectorComponents:Array<String> = [ 'x', 'y', 'z', 'w' ];
}