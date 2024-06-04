class NodeVar {
  public var isNodeVar:Bool = true;
  public var name:String;
  public var type:Dynamic;

  public function new(name:String, type:Dynamic) {
    this.name = name;
    this.type = type;
  }
}


**Explanation:**

* **Class declaration:**  `class NodeVar { ... }`  defines the class `NodeVar` in Haxe.
* **Public variables:** `public var isNodeVar:Bool = true;`, `public var name:String;`, and `public var type:Dynamic;` declare public variables with their corresponding types.
* **Constructor:** `public function new(name:String, type:Dynamic) { ... }` defines the constructor, which initializes the `name` and `type` variables using the provided parameters.
* **`Dynamic` type:** Haxe uses the `Dynamic` type to represent values that can be of any type. This allows the `type` variable to hold different data types. 

**Exporting:** 

Haxe doesn't have a direct equivalent of JavaScript's `export default`. You can use the `@:build` metadata to specify how the class should be exported in different targets:


@:build(haxe.macro.Build.MODULE)
class NodeVar {
  // ... (rest of the class code)
}