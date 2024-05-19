package three.js.playground.editors;

import three.js.playground.BaseNodeEditor;
import three.js.playground.NodeEditorUtils;

class FloatEditor extends BaseNodeEditor {

    public function new() {
        super();

        var json:Object = {
            inputType: 'float',
            inputConnection: false
        };

        var result:Array<Dynamic> = NodeEditorUtils.createElementFromJSON(json);
        var element:Dynamic = result[0];
        var inputNode:Dynamic = result[1];

        super('Float', inputNode, 150);

        element.addEventListener('changeInput', function(_) {
            invalidate();
        });

        add(element);
    }

}