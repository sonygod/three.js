package three.js.playground.editors;

import js.html.Element;
import js.html.Event;

class Vector4Editor extends BaseNodeEditor {
    public function new() {
        super("Vector 4", createElementFromJSON({
            inputType: 'vec4',
            inputConnection: false
        }).inputNode, 350);

        var element:Element = createElementFromJSON({
            inputType: 'vec4',
            inputConnection: false
        }).element;

        element.addEventListener("changeInput", function(event:Event) {
            invalidate();
        });

        add(element);
    }
}