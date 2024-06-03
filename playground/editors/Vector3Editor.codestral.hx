import BaseNodeEditor from '../BaseNodeEditor';
import NodeEditorUtils from '../NodeEditorUtils';
import haxe.ui.core.UIEvent;

class Vector3Editor extends BaseNodeEditor {

    public function new() {

        var json = {
            inputType: 'vec3',
            inputConnection: false
        };

        var { element, inputNode } = NodeEditorUtils.createElementFromJSON(json);

        super("Vector 3", inputNode, 325);

        element.addEventListener(UIEvent.CHANGE_INPUT, (event:UIEvent) -> {
            this.invalidate();
        });

        this.add(element);

    }

}