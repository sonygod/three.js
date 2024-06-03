import js.html.UIElement;
import js.html.Event;
import UIPanel from './libs/ui.hx'; // assuming UIPanel is also written in Haxe

extern class ViewHelperBase {
    public function new(editorCamera:Dynamic, container:UIElement)
}

class ViewHelper extends ViewHelperBase {
    public function new(editorCamera:Dynamic, container:UIPanel) {
        super(editorCamera, container.dom);

        var panel = new UIPanel();
        panel.setId('viewHelper');
        panel.setPosition('absolute');
        panel.setRight('0px');
        panel.setBottom('0px');
        panel.setHeight('128px');
        panel.setWidth('128px');

        panel.dom.addEventListener('pointerup', function(event:Event) {
            event.stopPropagation();
            this.handleClick(event);
        }.bind(this));

        panel.dom.addEventListener('pointerdown', function(event:Event) {
            event.stopPropagation();
        });

        container.add(panel);
    }
}