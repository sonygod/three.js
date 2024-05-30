import js.Browser.Window;
import js.html.Element;
import js.html.Input;
import js.html.LabelElement;

class SliderEditor extends BaseNodeEditor {
    public function new() {
        var node = float(0);
        super('Slider', node);
        this.collapse = true;
        var field = new SliderInput(0, 0, 1);
        field.onChange(function() {
            node.value = field.getValue();
        });
        var minInput = new NumberInput();
        var maxInput = new NumberInput(1);
        var minElement = new LabelElement('Min.');
        var maxElement = new LabelElement('Max.');
        var moreElement = new Element();
        var updateRange = function() {
            var min = minInput.getValue();
            var max = maxInput.getValue();
            if (min <= max) {
                field.setRange(min, max);
            } else {
                maxInput.setValue(min);
            }
        };
        minInput.onChange(updateRange);
        maxInput.onChange(updateRange);
        minElement.add(minInput);
        maxElement.add(maxInput);
        moreElement.add(new ButtonInput('More').onClick(function() {
            minElement.setVisible(true);
            maxElement.setVisible(true);
            moreElement.setVisible(false);
        }));
        this.add(new Element().add(field));
        this.add(minElement);
        this.add(maxElement);
        this.add(moreElement);
        this.onBlur(function() {
            minElement.setVisible(false);
            maxElement.setVisible(false);
            moreElement.setVisible(true);
        });
    }
}