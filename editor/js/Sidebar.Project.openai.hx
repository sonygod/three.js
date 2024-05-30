package three.js.editor.js;

import js.html.Window;
import ui.UISpan;

class SidebarProject {
  public function new(editor:Dynamic) {
    var container = new UISpan();

    container.add(new SidebarProjectRenderer(editor));

    //container.add(new SidebarProjectMaterials(editor)); // commented out

    container.add(new SidebarProjectApp(editor));

    container.add(new SidebarProjectImage(editor));

    if (Window.exists('SharedArrayBuffer')) {
      container.add(new SidebarProjectVideo(editor));
    }

    return container;
  }
}