import BaseNodeEditor;
import NodeEditorUtils;

class FloatEditor extends BaseNodeEditor {

    public function new() {

        var { element, inputNode } = NodeEditorUtils.createElementFromJSON( {
            inputType: 'float',
            inputConnection: false
        });

        super('Float', inputNode, 150);

        element.addEventListener('changeInput', () -> {
            this.invalidate();
        });

        this.add(element);

    }

}