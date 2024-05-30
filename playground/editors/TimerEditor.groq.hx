package three.js.playground.editors;

import flow.NumberInput;
import flow.LabelElement;
import flow.Element;
import flow.ButtonInput;
import three.nodes.timerLocal;
import BaseNodeEditor;

class TimerEditor extends BaseNodeEditor {
    
    public function new() {
        super("Timer", timerLocal(), 200);
        this.title.setIcon("ti ti-clock");

        var node = timerLocal();
        var field = new NumberInput();
        var scaleField = new NumberInput(1);

        field.onChange(function() {
            node.value = field.getValue();
        });

        scaleField.onChange(function() {
            node.scale = scaleField.getValue();
        });

        var moreElement = new Element().add(new ButtonInput("Reset").onClick(function() {
            node.value = 0;
            updateField();
        })).setSerializable(false);

        this.add(new Element().add(field).setSerializable(false))
            .add(new LabelElement("Speed").add(scaleField))
            .add(moreElement);

        // extends node
        node._update = node.update;
        node.update = function(params:Array<Any>) {
            node._update(params);
            updateField();
        };
    }

    private function updateField() {
        field.setValue(Std.string(node.value.toFixed(3)));
    }
}