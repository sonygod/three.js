package three.js.playground.editors;

import js.html.Element;
import js.html.Event;

class Vector3Editor extends BaseNodeEditor {
    public function new() {
        var element:Element = createElementFromJSON({
            inputType: 'vec3',
            inputConnection: false
        }).element;
        var inputNode = createElementFromJSON({
            inputType: 'vec3',
            inputConnection: false
        }).inputNode;
        
        super('Vector 3', inputNode, 325);

        element.addEventListener('changeInput', function(event:Event) {
            this.invalidate();
        });

        this.add(element);
    }
}