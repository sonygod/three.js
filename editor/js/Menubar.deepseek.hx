import three.js.editor.js.libs.ui.UIPanel;

import three.js.editor.js.Menubar.MenubarAdd;
import three.js.editor.js.Menubar.MenubarEdit;
import three.js.editor.js.Menubar.MenubarFile;
import three.js.editor.js.Menubar.MenubarView;
import three.js.editor.js.Menubar.MenubarHelp;
import three.js.editor.js.Menubar.MenubarStatus;

class Menubar {

	public function new(editor:Dynamic) {

		var container = new UIPanel();
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