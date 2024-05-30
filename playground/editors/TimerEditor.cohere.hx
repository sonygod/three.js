import js.flow.NumberInput;
import js.flow.LabelElement;
import js.flow.Element;
import js.flow.ButtonInput;

class TimerEditor extends BaseNodeEditor {
	public function new() {
		var node = timerLocal();
		super("Timer", node, 200);
		this.title.setIcon("ti ti-clock");

		function updateField() {
			field.setValue(Std.string(node.value));
		}

		var field = new NumberInput();
		field.onChange = function() {
			node.value = field.getValue();
		};

		var scaleField = new NumberInput(1);
		scaleField.onChange = function() {
			node.scale = scaleField.getValue();
		};

		var moreElement = new Element();
		var resetButton = new ButtonInput("Reset");
		resetButton.onClick = function() {
			node.value = 0;
			updateField();
		};
		moreElement.add(resetButton);
		moreElement.setSerializable(false);

		this.add(new Element().add(field).setSerializable(false));
		this.add(new LabelElement("Speed").add(scaleField));
		this.add(moreElement);

		node._update = node.update;
		node.update = function(_) {
			node._update(_);
			updateField();
		};
	}
}