package three.js.editor.js;

import js.html.DOMElement;
import js.Browser;

class ViewHelper extends ViewHelperBase {
    public function new(editorCamera:Dynamic, container:DOMElement) {
        super(editorCamera, container);

        var panel = new UIPanel();
        panel.setId('viewHelper');
        panel.setPosition('absolute');
        panel.setRight('0px');
        panel.setBottom('0px');
        panel.setHeight('128px');
        panel.setWidth('128px');

        panel.dom.addEventListener('pointerup', function(event) {
            event.stopPropagation();
            handleClick(event);
        });

        panel.dom.addEventListener('pointerdown', function(event) {
            event.stopPropagation();
        });

        container.appendChild(panel.dom);
    }

    private function handleClick(event:Dynamic):Void {
        // TO DO: implement handleClick method
    }
}