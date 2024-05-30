package three.js.playground.editors;

import js.Lib;
import js.html.Element;
import js.html.Event;

class StringEditor extends BaseNodeEditor {
    public function new() {
        var jsonObject = { inputType: 'string', inputConnection: false };
        var result = createElementFromJSON(jsonObject);
        var element = result.element;
        var inputNode = result.inputNode;
        super('String', inputNode, 350);
        element.addEventListener('changeInput', function(_) { invalidate(); });
        add(element);
    }

    public var stringNode(get, never):Dynamic;

    function get_stringNode():Dynamic {
        return value;
    }

    public function getURL():String {
        return stringNode.value;
    }
}