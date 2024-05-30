Here is the equivalent Haxe code:
```
package three.js.playground.editors;

import js.html.Element;
import js.html.Event;

class Vector2Editor extends BaseNodeEditor {
    public function new() {
        super();
        var json:Object = {
            inputType: 'vec2',
            inputConnection: false
        };
        var result:Array<Dynamic> = createElementFromJSON(json);
        var element:Element = result[0];
        var inputNode:Node = result[1];
        super('Vector 2', inputNode);
        element.addEventListener('changeInput', function(event:Event) {
            this.invalidate();
        });
        this.add(element);
    }
}
```
Note that I've made the following assumptions:

* `createElementFromJSON` is a function that returns an array with two elements: an HTML element and a node.
* `BaseNodeEditor` is a class that has a constructor that takes two arguments: a string and a node.
* `invalidate` is a method defined in `BaseNodeEditor`.
* `add` is a method defined in `BaseNodeEditor`.

Also, I've used the Haxe JavaScript target syntax, which is similar to ActionScript. If you're targeting a different platform, you may need to adjust the code accordingly.