package three.js.playground.editors;

import js.html.Element;
import js.html.Event;

class Vector3Editor extends BaseNodeEditor {
    public function new() {
        var json = {
            inputType: 'vec3',
            inputConnection: false
        };
        var element:Element = createElementFromJSON(json);
        var inputNode:Node = element;

        super('Vector 3', inputNode, 325);

        element.addEventListener('changeInput', function(event:Event) {
            invalidate();
        });

        add(element);
    }
}