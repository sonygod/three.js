package three.js.playground.editors;

import three.js.playground.BaseNodeEditor;
import three.js.playground.NodeEditorUtils;

class FloatEditor extends BaseNodeEditor {

    public function new() {
        var elementAndInputNode = NodeEditorUtils.createElementFromJSON({
            inputType: 'float',
            inputConnection: false
        });
        var element = elementAndInputNode.element;
        var inputNode = elementAndInputNode.inputNode;

        super('Float', inputNode, 150);

        element.addEventListener('changeInput', function() {
            this.invalidate();
        });

        this.add(element);
    }
}