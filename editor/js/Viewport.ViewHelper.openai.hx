package three.js.editor.js;

import js.html.DOMElement;
import js.Browser;
import.ui.UIPanel;

import three.addons.helpers.ViewHelperBase;

class ViewHelper extends ViewHelperBase {
    public function new(editorCamera:Dynamic, container:DOMElement) {
        super(editorCamera, container);

        var panel:UIPanel = new UIPanel();
        panel.setId('viewHelper');
        panel.setPosition('absolute');
        panel.setRight('0px');
        panel.setBottom('0px');
        panel.setHeight('128px');
        panel.setWidth('128px');

        panel.dom.addEventListener('pointerup', function(event:js.html.PointerEvent) {
            event.stopPropagation();
            handleClick(event);
        });

        panel.dom.addEventListener('pointerdown', function(event:js.html.PointerEvent) {
            event.stopPropagation();
        });

        container.add(panel);
    }

    private function handleClick(event:js.html.PointerEvent):Void {
        // implement handleClick logic here
    }
}

// Export the class
@:expose("ViewHelper")
class __ViewHelper extends ViewHelper {}