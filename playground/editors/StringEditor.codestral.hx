import BaseNodeEditor from '../BaseNodeEditor';
import { createElementFromJSON } from '../NodeEditorUtils';

class StringEditor extends BaseNodeEditor {

    public function new() {
        var elementInfo = createElementFromJSON( {
            inputType: 'string',
            inputConnection: false
        } );

        super('String', elementInfo.inputNode, 350);

        elementInfo.element.addEventListener('changeInput', () -> {
            this.invalidate();
            return;
        });

        this.add(elementInfo.element);
    }

    public function get stringNode():String {
        return this.value;
    }

    public function getURL():String {
        return this.stringNode.value;
    }
}