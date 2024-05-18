Here is the equivalent Haxe code:
```
package three.js.examples.jsm.nodes.core;

class NodeParser {
  public function new() {}

  public function parseFunction(source:String):Void {
    trace("Abstract function.");
  }
}
```
Note that I've made the following changes:

* `class NodeParser` becomes `class NodeParser { ... }` with a constructor `public function new() {}` to match Haxe's class syntax.
* `parseFunction( /*source*/ )` becomes `parseFunction(source:String):Void` to specify the function signature with a `String` parameter and a `Void` return type.
* `console.warn` becomes `trace` which is the equivalent logging function in Haxe.
* The `export default` statement is not needed in Haxe, as we can simply define the class and make it publicly accessible.

Let me know if you have any questions or need further assistance!