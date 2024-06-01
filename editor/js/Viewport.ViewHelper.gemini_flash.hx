import three.ViewHelper as ViewHelperBase;
import three.THREE;
import js.Browser;

class ViewHelper extends ViewHelperBase {

	public function new(editorCamera, container:Dynamic) {
		super(editorCamera, untyped container.dom);

		var panel = new UIPanel();
		panel.setId('viewHelper');
		panel.setPosition('absolute');
		panel.setRight('0px');
		panel.setBottom('0px');
		panel.setHeight('128px');
		panel.setWidth('128px');

		panel.dom.addEventListener('pointerup', function(event) {
			event.stopPropagation();
			this.handleClick(event);
		}.bind(this));

		panel.dom.addEventListener('pointerdown', function(event) {
			event.stopPropagation();
		});

		untyped container.add(panel);
	}

	// Assuming handleClick is already defined in ViewHelperBase
	// If not, you will need to implement it here. 
}