import three.js.playground.editors.BaseNodeEditor;
import three.js.playground.editors.NodeEditorUtils.createElementFromJSON;

class StringEditor extends BaseNodeEditor {

    public function new() {

        var config = {
            inputType: "string",
            inputConnection: false
        };

        var elementAndInputNode = createElementFromJSON(config);
        var element = elementAndInputNode.element;
        var inputNode = elementAndInputNode.inputNode;

        super("String", inputNode, 350);

        element.addEventListener("changeInput", function() {
            invalidate();
        });

        this.add(element);

    }

    public function get_stringNode(): Dynamic {
        return this.value;
    }

    public function getURL(): String {
        return cast this.stringNode.value;
    }

}