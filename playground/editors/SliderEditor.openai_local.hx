import flow.ButtonInput;
import flow.SliderInput;
import flow.NumberInput;
import flow.LabelElement;
import flow.Element;
import three.nodes.FloatNode;
import three.js.playground.editors.BaseNodeEditor;

class SliderEditor extends BaseNodeEditor {

    public function new() {
        var node = new FloatNode(0);

        super('Slider', node);

        this.collapse = true;

        var field = new SliderInput(0, 0, 1).onChange(function() {
            node.value = field.getValue();
        });

        var updateRange = function() {
            var min = minInput.getValue();
            var max = maxInput.getValue();

            if (min <= max) {
                field.setRange(min, max);
            } else {
                maxInput.setValue(min);
            }
        };

        var minInput = new NumberInput().onChange(updateRange);
        var maxInput = new NumberInput(1).onChange(updateRange);

        var minElement = new LabelElement('Min.').add(minInput).setVisible(false);
        var maxElement = new LabelElement('Max.').add(maxInput).setVisible(false);

        var moreElement = new Element().add(new ButtonInput('More').onClick(function() {
            minElement.setVisible(true);
            maxElement.setVisible(true);
            moreElement.setVisible(false);
        })).setSerializable(false);

        this.add(new Element().add(field))
            .add(minElement)
            .add(maxElement)
            .add(moreElement);

        this.onBlur(function() {
            minElement.setVisible(false);
            maxElement.setVisible(false);
            moreElement.setVisible(true);
        });
    }
}