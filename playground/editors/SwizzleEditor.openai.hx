package three.js.playground.editors;

import flow.LabelElement;
import BaseNodeEditor;

class SwizzleEditor extends BaseNodeEditor {
    public function new() {
        super("Swizzle", split(float(), 'x'), 175);

        var inputElement = setInputAestheticsFromType(new LabelElement('Input'), 'node');
        inputElement.onConnect(function() {
            node.node = inputElement.getLinkedObject() || float();
        });
        add(inputElement);

        var componentsElement = createElementFromJSON({
            inputType: 'String',
            allows: 'xyzwrgba',
            transform: 'lowercase',
            options: ['x', 'y', 'z', 'w', 'r', 'g', 'b', 'a'],
            maxLength: 4
        });
        componentsElement.addEventListener('changeInput', function() {
            var string = componentsElement.value.value;
            node.components = string || 'x';
            invalidate();
        });
        add(componentsElement);
    }
}