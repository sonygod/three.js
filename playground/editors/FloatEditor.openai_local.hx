import three.js.playground.editors.BaseNodeEditor;
import three.js.playground.editors.NodeEditorUtils.createElementFromJSON;

class FloatEditor extends BaseNodeEditor {

    public function new() {

        var result = createElementFromJSON({
            inputType: 'float',
            inputConnection: false
        });

        var element = result.element;
        var inputNode = result.inputNode;

        super('Float', inputNode, 150);

        element.addEventListener('changeInput', function() {
            this.invalidate();
        }.bind(this));

        this.add(element);

    }

}