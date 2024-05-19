package three.js.playground.editors;

import three.js.playground.BaseNodeEditor;
import three.js.playground.NodeEditorUtils;

class Vector2Editor extends BaseNodeEditor {
    public function new() {
        super();
        var element:HTMLElement = NodeEditorUtils.createElementFromJSON({
            inputType: 'vec2',
            inputConnection: false
        }).element;
        var inputNode:Dynamic = NodeEditorUtils.createElementFromJSON({
            inputType: 'vec2',
            inputConnection: false
        }).inputNode;
        super('Vector 2', inputNode);
        element.addEventListener('changeInput', function(_) {
            invalidate();
        });
        add(element);
    }
}