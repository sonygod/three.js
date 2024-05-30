import three.js.playground.editors.BaseNodeEditor;
import three.js.playground.editors.NodeEditorUtils;

class Vector3Editor extends BaseNodeEditor {

    public function new() {

        var elementInputNode = NodeEditorUtils.createElementFromJSON({
            inputType: 'vec3',
            inputConnection: false
        });

        var element = elementInputNode.element;
        var inputNode = elementInputNode.inputNode;

        super('Vector 3', inputNode, 325);

        element.addEventListener('changeInput', function(_) {
            this.invalidate();
        });

        this.add(element);

    }

}