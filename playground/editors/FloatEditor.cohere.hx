import js.Browser.DomEvent;
import js.Browser.Event;

class FloatEditor extends BaseNodeEditor {
	public function new() {
		var element = createElementFromJSON({
			inputType: 'float',
			inputConnection: false
		});

		super('Float', element.inputNode, 150);

		var onChangeInput = function(_) {
			invalidate();
		};
		DomEvent.listen(element.element, 'changeInput', onChangeInput);

		add(element);
	}
}