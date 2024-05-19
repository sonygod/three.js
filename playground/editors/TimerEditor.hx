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

        var updateField = function() {
            field.setValue(Std.string(node.value, 3));
        };

        var field = new NumberInput();
        field.onChange(function() {
            node.value = field.getValue();
        });

        var scaleField = new NumberInput(1);
        scaleField.onChange(function() {
            node.scale = scaleField.getValue();
        });

        var moreElement = new Element();
        moreElement.add(new ButtonInput('Reset').onClick(function() {
            node.value = 0;
            updateField();
        }));
        moreElement.setSerializable(false);

        add(new Element().add(field).setSerializable(false));
        add(new LabelElement('Speed').add(scaleField));
        add(moreElement);

        // extends node
        node._update = node.update;
        node.update = function(...params) {
            node._update(...params);
            updateField();
        };
    }
}