import three.js.editor.js.libs.ui.UISpan;

import three.js.editor.js.Sidebar.Project.App.SidebarProjectApp;
// import three.js.editor.js.Sidebar.Project.Materials.SidebarProjectMaterials;
import three.js.editor.js.Sidebar.Project.Renderer.SidebarProjectRenderer;
import three.js.editor.js.Sidebar.Project.Image.SidebarProjectImage;
import three.js.editor.js.Sidebar.Project.Video.SidebarProjectVideo;

class SidebarProject {

	public function new(editor:Dynamic) {

		var container = new UISpan();

		container.add(new SidebarProjectRenderer(editor));

		// container.add(new SidebarProjectMaterials(editor));

		container.add(new SidebarProjectApp(editor));

		container.add(new SidebarProjectImage(editor));

		if ('SharedArrayBuffer' in js.Browser.window) {

			container.add(new SidebarProjectVideo(editor));

		}

		return container;

	}

}