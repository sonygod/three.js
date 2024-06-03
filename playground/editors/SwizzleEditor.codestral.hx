import flow.LabelElement;
import BaseNodeEditor;
import NodeEditorUtils;
import three.nodes.Split;
import three.nodes.Float;
import DataTypeLib;
import js.html.InputElement;

class SwizzleEditor extends BaseNodeEditor {

    public function new() {

        var node: Split = new Split(new Float(), 'x');

        super('Swizzle', node, 175);

        var inputElement: LabelElement = DataTypeLib.setInputAestheticsFromType(new LabelElement('Input'), 'node');
        inputElement.onConnect(function() {

            node.node = inputElement.getLinkedObject() != null ? inputElement.getLinkedObject() : new Float();

        });

        this.add(inputElement);

        var componentsElement: InputElement = NodeEditorUtils.createElementFromJSON({
            inputType: 'String',
            allows: 'xyzwrgba',
            transform: 'lowercase',
            options: ['x', 'y', 'z', 'w', 'r', 'g', 'b', 'a'],
            maxLength: 4
        }).element;

        componentsElement.addEventListener('changeInput', function(_) {

            var string: String = componentsElement.value.value;

            node.components = string != null ? string : 'x';

            this.invalidate();

        });

        this.add(componentsElement);

    }

}