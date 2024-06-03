enum NodeShaderStage {
    VERTEX("vertex"),
    FRAGMENT("fragment");

    public var value: String;

    function new(value: String) {
        this.value = value;
    }
}

enum NodeUpdateType {
    NONE("none"),
    FRAME("frame"),
    RENDER("render"),
    OBJECT("object");

    public var value: String;

    function new(value: String) {
        this.value = value;
    }
}

enum NodeType {
    BOOLEAN("bool"),
    INTEGER("int"),
    FLOAT("float"),
    VECTOR2("vec2"),
    VECTOR3("vec3"),
    VECTOR4("vec4"),
    MATRIX2("mat2"),
    MATRIX3("mat3"),
    MATRIX4("mat4");

    public var value: String;

    function new(value: String) {
        this.value = value;
    }
}

final var defaultShaderStages: Array<String> = [ NodeShaderStage.FRAGMENT.value, NodeShaderStage.VERTEX.value ];
final var defaultBuildStages: Array<String> = [ "setup", "analyze", "generate" ];
final var shaderStages: Array<String> = defaultShaderStages.concat(["compute"]);
final var vectorComponents: Array<String> = [ "x", "y", "z", "w" ];