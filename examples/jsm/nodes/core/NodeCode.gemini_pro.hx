class NodeCode {

	public var name:String;
	public var type:String;
	public var code:String;

	public function new(name:String, type:String, code:String = "") {
		this.name = name;
		this.type = type;
		this.code = code;
	}

	public var isNodeCode:Bool = true;

}


**Explanation:**

* **Class declaration:** The `class NodeCode` declaration remains the same, defining a class named `NodeCode`.
* **Member variables:** The `name`, `type`, and `code` variables are declared as `public var` in Haxe, similar to `public` in JavaScript.
* **Constructor:** The `new` function acts as the constructor in Haxe. It takes the same arguments as the JavaScript constructor and initializes the member variables.
* **`isNodeCode` property:**  The `isNodeCode` property is declared as a `public var` and set to `true` directly within the constructor. There's no need for `Object.defineProperty` in Haxe.

**Exporting:**

Haxe doesn't use `export default` like JavaScript. To make the `NodeCode` class accessible from other Haxe files, you need to either:

1. **Put it in a separate file:** Create a file named `NodeCode.hx` and place the code there.
2. **Import it:** In the file where you want to use the `NodeCode` class, add the following line:

   
   import NodeCode;