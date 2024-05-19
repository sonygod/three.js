Here is the equivalent Haxe code:
```
package three.js.editor.js.libs;

import js.html.DivElement;

class UIRow extends UIDiv {
  public function new() {
    super();
    cast(this.dom, DivElement).className = 'Row';
  }
}
```
Note:

* In Haxe, we need to specify the package and import the necessary classes.
* The `dom` property is assumed to be of type `js.html.DivElement`, so we need to cast it to access its `className` property.
* The `super()` call is implied in Haxe, so we don't need to write it explicitly.
* We use the `new` keyword to define the constructor, and `public function new()` is the Haxe equivalent of the JavaScript `constructor` function.

Please note that this conversion assumes that the `UIDiv` class is already defined in your Haxe project. If it's not, you'll need to define it as well.