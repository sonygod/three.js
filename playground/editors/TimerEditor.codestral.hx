import flow.NumberInput;
import flow.LabelElement;
import flow.Element;
import flow.ButtonInput;
import three.nodes.timerLocal;
import BaseNodeEditor;

class TimerEditor extends BaseNodeEditor {

	public function new() {

		var node = timerLocal();

		super("Timer", node, 200);

		this.title.setIcon("ti ti-clock");

		var updateField = function() {
			field.setValue(node.value.toFixed(3));
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
		moreElement.add(new ButtonInput("Reset"));
		moreElement.onClick(function() {
			node.value = 0;
			updateField();
		});
		moreElement.setSerializable(false);

		this.add(new Element().add(field).setSerializable(false));
		this.add(new LabelElement("Speed").add(scaleField));
		this.add(moreElement);

		// extends node
		node._update = node.update;
		node.update = function(params: Array<Dynamic>) {
			this._update(params);
			updateField();
		};
	}
}