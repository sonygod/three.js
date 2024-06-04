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


Here's a breakdown of the changes:

* **Class Declaration:**  Haxe uses the `class` keyword, similar to JavaScript.
* **Member Variables:**  Haxe uses `public var` to declare public member variables within the class.
* **Constructor:**  The constructor is defined using the `new` keyword and takes parameters.
* **Object.defineProperty:**  Haxe doesn't directly use `Object.defineProperty`. Instead, it uses the `var` declaration with a default value to achieve the same effect. The `isNodeCode` property is now a regular `var`. 
* **Export:** Haxe doesn't have an explicit `export` keyword. If you want to use this class in another Haxe file, you need to make sure it's in a separate file and compile it with the `-cp` flag, or use a Haxelib library.

**Key Points:**

* Haxe is a statically typed language, so you need to specify the types of variables (e.g., `String`, `Bool`).
* Haxe uses a different syntax for class declarations and constructors.
* The `Object.defineProperty` equivalent in Haxe is simply declaring a variable with a default value.

**Example Usage:**


var nodeCode = new NodeCode("myNode", "function", "console.log('Hello!');");

trace(nodeCode.name); // Outputs: "myNode"
trace(nodeCode.isNodeCode); // Outputs: true