package three.js.playground.editors;

import flow.NumberInput;
import flow.LabelElement;
import flow.Element;
import flow.ButtonInput;
import three.nodes.timerLocal;

class TimerEditor extends BaseNodeEditor {
    public function new() {
        var node = timerLocal();

        super('Timer', node, 200);

        title.setIcon('ti ti-clock');

        var field = new NumberInput();
        field.onChange(function() {
            node.value = field.getValue();
        });

        var scaleField = new NumberInput(1);
        scaleField.onChange(function() {
            node.scale = scaleField.getValue();
        });

        var moreElement = new Element();
        var resetButton = new ButtonInput('Reset');
        resetButton.onClick(function() {
            node.value = 0;
            updateField();
        });
        moreElement.add(resetButton);
        moreElement.setSerializable(false);

        this.add(new Element().add(field).setSerializable(false));
        this.add(new LabelElement('Speed').add(scaleField));
        this.add(moreElement);

        node._update = node.update;
        node.update = function(params:Array<Dynamic>) {
            node._update(params);
            updateField();
        };

        function updateField() {
            field.setValue(node.value.toFixed(3));
        }
    }
}