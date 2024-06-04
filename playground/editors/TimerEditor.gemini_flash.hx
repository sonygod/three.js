import flow.NumberInput;
import flow.LabelElement;
import flow.Element;
import flow.ButtonInput;
import BaseNodeEditor from "../BaseNodeEditor";
import three.nodes.timerLocal;

class TimerEditor extends BaseNodeEditor {

	public function new() {
		var node = timerLocal();
		super("Timer", node, 200);
		this.title.setIcon("ti ti-clock");

		var updateField = function() {
			field.setValue(node.value.toFixed(3));
		};

		var field = new NumberInput().onChange(function() {
			node.value = field.getValue();
		});

		var scaleField = new NumberInput(1).onChange(function() {
			node.scale = scaleField.getValue();
		});

		var moreElement = new Element()
			.add(new ButtonInput("Reset").onClick(function() {
				node.value = 0;
				updateField();
			}))
			.setSerializable(false);

		this.add(new Element().add(field).setSerializable(false))
			.add(new LabelElement("Speed").add(scaleField))
			.add(moreElement);

		// extends node
		node._update = node.update;
		node.update = function(...params:Dynamic) {
			this._update(...params);
			updateField();
		};
	}
}