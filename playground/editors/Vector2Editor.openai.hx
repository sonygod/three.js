package three.js.playground.editors;

import three.js.playground.BaseNodeEditor;
import three.js.playground.NodeEditorUtils;

class Vector2Editor extends BaseNodeEditor {
    public function new() {
        super("Vector 2", NodeEditorUtils.createElementFromJSON({
            inputType: "vec2",
            inputConnection: false
        }).inputNode);

        var element:js.html.Element = NodeEditorUtils.createElementFromJSON({
            inputType: "vec2",
            inputConnection: false
        }).element;

        element.addEventListener("changeInput", function() {
            invalidate();
        });

        add(element);
    }
}