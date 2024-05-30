package three.js.playground.editors;

import three.js.playground.BaseNodeEditor;
import three.js.playground.NodeEditorUtils;

class FloatEditor extends BaseNodeEditor {

    public function new() {
        super();

        var createElementFromJSONResult = NodeEditorUtils.createElementFromJSON({
            inputType: 'float',
            inputConnection: false
        });

        var element = createElementFromJSONResult.element;
        var inputNode = createElementFromJSONResult.inputNode;

        super('Float', inputNode, 150);

        element.addEventListener('changeInput', function() {
            invalidate();
        });

        add(element);
    }

}