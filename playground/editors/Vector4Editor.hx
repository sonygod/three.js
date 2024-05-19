package three.js.playground.editors;

import js.html.Element;
import js.Node;

class Vector4Editor extends BaseNodeEditor {
    public function new() {
        super('Vector 4', createNode('vec4', false), 350);
        var element:Element = cast createElementFromJSON({
            inputType: 'vec4',
            inputConnection: false
        }).element;
        element.addEventListener('changeInput', function(_) {
            invalidate();
        });
        add(element);
    }

    static function createElementFromJSON(opts:Dynamic):{ element:Element, inputNode:Node } {
        // You'll need to implement this function according to your NodeEditorUtils.js
        // This is just a placeholder
        // You can use js.Browser.get() or js.Browser.createElement() to create elements
        throw "not implemented";
    }
}