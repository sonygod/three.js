package three.js.editor.js;

import js.html.DivElement;
import ui.UIPanel;

class Menubar {
    public function new(editor:Dynamic) {
        var container:UIPanel = new UIPanel();
        container.setId('menubar');

        container.add(new MenubarFile(editor));
        container.add(new MenubarEdit(editor));
        container.add(new MenubarAdd(editor));
        container.add(new MenubarView(editor));
        container.add(new MenubarHelp(editor));
        container.add(new MenubarStatus(editor));

        return container;
    }
}