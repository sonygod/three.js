package three.js.playground.editors;

import flow.LabelElement;
import BaseNodeEditor;
import NodeEditorUtils.createElementFromJSON;
import three.nodes.split;
import three.nodes.float;
import DataTypeLib.setInputAestheticsFromType;

class SwizzleEditor extends BaseNodeEditor {

    public function new() {
        super('Swizzle', split(float(), 'x'), 175);

        var inputElement:LabelElement = setInputAestheticsFromType(new LabelElement('Input'), 'node');
        inputElement.onConnect = function() {
            node.node = inputElement.getLinkedObject() || float();
        };
        this.add(inputElement);

        var componentsElement = createElementFromJSON({
            inputType: 'String',
            allows: 'xyzwrgba',
            transform: 'lowercase',
            options: ['x', 'y', 'z', 'w', 'r', 'g', 'b', 'a'],
            maxLength: 4
        }).element;
        componentsElement.addEventListener('changeInput', function() {
            var string:String = componentsElement.value.value;
            node.components = string != null ? string : 'x';
            this.invalidate();
        });
        this.add(componentsElement);
    }

}