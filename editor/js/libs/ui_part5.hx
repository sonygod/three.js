Here is the equivalent Haxe code:
```
package three.js.editor.js.libs;

import js.html.DivElement;

class UIPanel extends UIDiv {
  
  public function new() {
    super();
    cast(this.dom, DivElement).className = 'Panel';
  }
}
```
Note that I've assumed that `UIDiv` is a class that is already defined in your Haxe project, and that it has a `dom` property that is a `js.html.DivElement`.

Also, I've used the `cast` function to cast the `dom` property to a `DivElement` to access its `className` property. This is because Haxe is a statically-typed language, and we need to ensure that the type system is aware of the type of `dom` at compile-time.

You can adjust the package name and imports according to your Haxe project's structure and requirements.