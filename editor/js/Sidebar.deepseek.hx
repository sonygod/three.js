import three.js.editor.js.libs.ui.UITabbedPanel;
import three.js.editor.js.libs.ui.UISpan;

import three.js.editor.js.Sidebar.SidebarScene;
import three.js.editor.js.Sidebar.SidebarProperties;
import three.js.editor.js.Sidebar.SidebarProject;
import three.js.editor.js.Sidebar.SidebarSettings;

class Sidebar {

	public function new(editor:Dynamic) {

		var strings = editor.strings;

		var container = new UITabbedPanel();
		container.setId('sidebar');

		var scene = new UISpan().add(
			new SidebarScene(editor),
			new SidebarProperties(editor)
		);
		var project = new SidebarProject(editor);
		var settings = new SidebarSettings(editor);

		container.addTab('scene', strings.getKey('sidebar/scene'), scene);
		container.addTab('project', strings.getKey('sidebar/project'), project);
		container.addTab('settings', strings.getKey('sidebar/settings'), settings);
		container.select('scene');

		return container;

	}

}