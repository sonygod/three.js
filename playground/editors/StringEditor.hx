package three.playground.editors;

import three.BaseNodeEditor;
import three.NodeEditorUtils;

class StringEditor extends BaseNodeEditor {
    public function new() {
        super("String", createElementFromJSON({
            inputType: "string",
            inputConnection: false
        }).inputNode, 350);

        var element = createElementFromJSON({
            inputType: "string",
            inputConnection: false
        }).element;

        element.addEventListener("changeInput", function(_) {
            invalidate();
        });

        add(element);
    }

    public var stringValue(get, null):String;

    private function get_stringValue():String {
        return value;
    }

    public function getURL():String {
        return stringValue;
    }
}