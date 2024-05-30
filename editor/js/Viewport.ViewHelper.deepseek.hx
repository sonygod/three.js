import three.addons.helpers.ViewHelper;
import three.js.editor.js.libs.ui.UIPanel;

class ViewHelper extends ViewHelper {

    public function new(editorCamera:Dynamic, container:Dynamic) {
        super(editorCamera, container.dom);

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
        });

        panel.dom.addEventListener('pointerdown', function(event) {
            event.stopPropagation();
        });

        container.add(panel);
    }
}