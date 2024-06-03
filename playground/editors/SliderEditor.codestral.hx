import flow.ButtonInput;
import flow.SliderInput;
import flow.NumberInput;
import flow.LabelElement;
import flow.Element;
import BaseNodeEditor;
import three.nodes.Float;

class SliderEditor extends BaseNodeEditor {
    public function new() {
        var node:Float = new Float(0.0);
        super("Slider", node);

        this.collapse = true;

        var field:SliderInput = new SliderInput(0, 0, 1);
        field.onChange(function() {
            node.value = field.getValue();
        });

        var updateRange = function() {
            var min:Float = minInput.getValue();
            var max:Float = maxInput.getValue();

            if (min <= max) {
                field.setRange(min, max);
            } else {
                maxInput.setValue(min);
            }
        };

        var minInput:NumberInput = new NumberInput();
        minInput.onChange(updateRange);
        var maxInput:NumberInput = new NumberInput(1);
        maxInput.onChange(updateRange);

        var minElement:LabelElement = new LabelElement("Min.").add(minInput).setVisible(false);
        var maxElement:LabelElement = new LabelElement("Max.").add(maxInput).setVisible(false);

        var moreElement:Element = new Element();
        moreElement.add(new ButtonInput("More").onClick(function() {
            minElement.setVisible(true);
            maxElement.setVisible(true);
            moreElement.setVisible(false);
        }));
        moreElement.setSerializable(false);

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