import flow.LabelElement;
import playground.editors.BaseNodeEditor;
import playground.NodeEditorUtils.createElementFromJSON;
import three.nodes.split;
import three.nodes.float;
import playground.DataTypeLib.setInputAestheticsFromType;

class SwizzleEditor extends BaseNodeEditor {

    public function new() {
        var node = split(float(), 'x');

        super('Swizzle', node, 175);

        var inputElement = setInputAestheticsFromType(new LabelElement('Input'), 'node').onConnect(() -> {
            node.node = inputElement.getLinkedObject() != null ? inputElement.getLinkedObject() : float();
        });

        this.add(inputElement);

        // Create components element from JSON
        var componentsJSON = {
            inputType: 'String',
            allows: 'xyzwrgba',
            transform: 'lowercase',
            options: ['x', 'y', 'z', 'w', 'r', 'g', 'b', 'a'],
            maxLength: 4
        };

        var componentsElement = createElementFromJSON(componentsJSON).element;

        componentsElement.addEventListener('changeInput', () -> {
            var string = componentsElement.value.value;
            node.components = string != null ? string : 'x';
            this.invalidate();
        });

        this.add(componentsElement);
    }
}