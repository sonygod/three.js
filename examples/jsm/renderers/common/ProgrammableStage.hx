Here is the converted Haxe code:
```
package three.js.examples.jm.renderers.common;

class ProgrammableStage {
    private static var _id:Int = 0;

    public var id:Int;
    public var code:String;
    public var stage:String;
    public var transforms:Null<Array<Transform>>;
    public var attributes:Null<Map<String, Dynamic>>;
    public var usedTimes:Int;

    public function new(code:String, type:String, ?transforms:Array<Transform>, ?attributes:Map<String, Dynamic>) {
        this.id = _id++;
        this.code = code;
        this.stage = type;
        this.transforms = transforms;
        this.attributes = attributes;
        this.usedTimes = 0;
    }
}
```
Note that I've made the following changes:

* `let` is not valid in Haxe, so I replaced it with `private static var`.
* `class` syntax is similar in Haxe, but `extends` is not needed since we're not inheriting from any base class.
* `constructor` is not needed in Haxe, and the `new` keyword is used to define the constructor function.
* `this` is used to refer to the current object, just like in JavaScript.
* `transforms` and `attributes` are made optional by adding `?` before their types, to match the JavaScript behavior.
* `usedTimes` is initialized to `0` in the constructor, as in the original JavaScript code.
* I've added the `package` declaration at the top, assuming that the file is located in the `three.js/examples/jm/renderers/common` directory.

Please note that I've assumed that `Transform` is a custom class, so I've kept it as is. If it's a built-in Haxe type, please let me know and I'll update the code accordingly.