import BaseNodeEditor from '../BaseNodeEditor';
import NodeEditorUtils from '../NodeEditorUtils';

class Vector4Editor extends BaseNodeEditor {
    public function new() {
        var data = {
            inputType: 'vec4',
            inputConnection: false
        }
        var element:Element = NodeEditorUtils.createElementFromJSON(data).element;
        super('Vector 4', NodeEditorUtils.createElementFromJSON(data).inputNode, 350);

        element.addEventListener('changeInput', () -> {
            this.invalidate();
        });

        this.add(element);
    }
}