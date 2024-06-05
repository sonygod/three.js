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

var defaultShaderStages:Array<String> = ['fragment', 'vertex'];
var defaultBuildStages:Array<String> = ['setup', 'analyze', 'generate'];
var shaderStages:Array<String> = ['fragment', 'vertex', 'compute'];
var vectorComponents:Array<String> = ['x', 'y', 'z', 'w'];