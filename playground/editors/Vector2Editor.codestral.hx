import BaseNodeEditor from '../BaseNodeEditor';
import NodeEditorUtils from '../NodeEditorUtils';

class Vector2Editor extends BaseNodeEditor {

    public function new() {
        var { element, inputNode } = NodeEditorUtils.createElementFromJSON({
            inputType: 'vec2',
            inputConnection: false
        });

        super('Vector 2', inputNode);

        element.addEventListener('changeInput', () -> this.invalidate());

        this.add(element);
    }

}