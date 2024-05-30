package three.js.playground.editors;

import js.html.Element;
import js.Node;

class Vector4Editor extends BaseNodeEditor {
    
    public function new() {
        var element:Element = createElementFromJSON({
            inputType: 'vec4',
            inputConnection: false
        }).element;
        var inputNode:Node = createElementFromJSON({
            inputType: 'vec4',
            inputConnection: false
        }).inputNode;
        
        super('Vector 4', inputNode, 350);
        
        element.addEventListener('changeInput', function() {
            invalidate();
        });
        
        add(element);
    }
}