package three.js.playground.editors;

import js.html.Element;
import js.html.Event;

class StringEditor extends BaseNodeEditor {
    private var element:Element;
    private var inputNode:Dynamic;

    public function new() {
        var json:Object = {
            inputType: 'string',
            inputConnection: false
        };
        var createElementFromJSONResult = createElementFromJSON(json);
        element = createElementFromJSONResult.element;
        inputNode = createElementFromJSONResult.inputNode;

        super('String', inputNode, 350);

        element.addEventListener('changeInput', function(event:Event) {
            invalidate();
        });

        add(element);
    }

    private var _stringNode:String;

    public function get_stringNode():String {
        return _stringNode;
    }

    public function getURL():String {
        return _stringNode;
    }
}