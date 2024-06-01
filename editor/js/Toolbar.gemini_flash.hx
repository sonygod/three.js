import js.Browser;
import js.html.Element;

class Toolbar {
	public var container:UIPanel;

	public function new(editor:Dynamic) {
		var signals = editor.signals;
		var strings = editor.strings;

		container = new UIPanel();
		container.setId('toolbar');

		// translate / rotate / scale

		var translateIcon:Element = Browser.document.createElement("img");
		translateIcon.title = strings.getKey('toolbar/translate');
		translateIcon.src = 'images/translate.svg';

		var translate = new UIButton();
		translate.dom.className = 'Button selected';
		translate.dom.appendChild(translateIcon);
		translate.onClick(function(_) {
			signals.transformModeChanged.dispatch('translate');
		});
		container.add(translate);

		var rotateIcon:Element = Browser.document.createElement("img");
		rotateIcon.title = strings.getKey('toolbar/rotate');
		rotateIcon.src = 'images/rotate.svg';

		var rotate = new UIButton();
		rotate.dom.appendChild(rotateIcon);
		rotate.onClick(function(_) {
			signals.transformModeChanged.dispatch('rotate');
		});
		container.add(rotate);

		var scaleIcon:Element = Browser.document.createElement("img");
		scaleIcon.title = strings.getKey('toolbar/scale');
		scaleIcon.src = 'images/scale.svg';

		var scale = new UIButton();
		scale.dom.appendChild(scaleIcon);
		scale.onClick(function(_) {
			signals.transformModeChanged.dispatch('scale');
		});
		container.add(scale);

		var local = new UICheckbox(false);
		local.dom.title = strings.getKey('toolbar/local');
		local.onChange(function(_) {
			signals.spaceChanged.dispatch(local.getValue() ? 'local' : 'world');
		});
		container.add(local);

		//

		signals.transformModeChanged.add(function(mode) {
			translate.dom.classList.remove('selected');
			rotate.dom.classList.remove('selected');
			scale.dom.classList.remove('selected');

			switch (mode) {
				case 'translate':
					translate.dom.classList.add('selected');
				case 'rotate':
					rotate.dom.classList.add('selected');
				case 'scale':
					scale.dom.classList.add('selected');
			}
		});
	}
}