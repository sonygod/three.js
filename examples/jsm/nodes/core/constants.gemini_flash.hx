class NodeShaderStage {
  public static var VERTEX:String = "vertex";
  public static var FRAGMENT:String = "fragment";
}

class NodeUpdateType {
  public static var NONE:String = "none";
  public static var FRAME:String = "frame";
  public static var RENDER:String = "render";
  public static var OBJECT:String = "object";
}

class NodeType {
  public static var BOOLEAN:String = "bool";
  public static var INTEGER:String = "int";
  public static var FLOAT:String = "float";
  public static var VECTOR2:String = "vec2";
  public static var VECTOR3:String = "vec3";
  public static var VECTOR4:String = "vec4";
  public static var MATRIX2:String = "mat2";
  public static var MATRIX3:String = "mat3";
  public static var MATRIX4:String = "mat4";
}

var defaultShaderStages:Array<String> = ["fragment", "vertex"];
var defaultBuildStages:Array<String> = ["setup", "analyze", "generate"];
var shaderStages:Array<String> = defaultShaderStages.concat(["compute"]);
var vectorComponents:Array<String> = ["x", "y", "z", "w"];


**Explanation:**

* **Enums in JavaScript vs Haxe:** JavaScript doesn't have enums like Haxe does. So, instead of using `export const` for each constant, we create separate classes in Haxe named `NodeShaderStage`, `NodeUpdateType`, and `NodeType`. Each class has static properties to represent the constants.
* **Static Properties:** We use `public static var` to declare the constants within each class, making them accessible using the class name (e.g., `NodeShaderStage.VERTEX`).
* **Arrays:** Haxe uses the `Array` type for arrays, and the syntax for creating and manipulating them is similar to JavaScript.
* **`concat()`:** We use the `concat()` method to add the "compute" stage to the `shaderStages` array.

**Using the Haxe code:**

You can access the constants using the class names:


trace(NodeShaderStage.VERTEX); // Outputs "vertex"
trace(NodeUpdateType.FRAME); // Outputs "frame"
trace(NodeType.VECTOR3); // Outputs "vec3"