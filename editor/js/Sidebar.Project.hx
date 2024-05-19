package three.js.editor.js;

import ui.UISpan;

import SidebarProjectApp;
// import SidebarProjectMaterials; // commented out, same as in JS code
import SidebarProjectRenderer;
import SidebarProjectImage;
import SidebarProjectVideo;

class SidebarProject {
    public function new(editor:Dynamic) {
        var container:UISpan = new UISpan();

        container.add(new SidebarProjectRenderer(editor));

        // container.add(new SidebarProjectMaterials(editor)); // commented out, same as in JS code

        container.add(new SidebarProjectApp(editor));

        container.add(new SidebarProjectImage(editor));

        if (js.Browser.supported) {
            if (js.Browser.window.SharedArrayBuffer != null) {
                container.add(new SidebarProjectVideo(editor));
            }
        }

        return container;
    }
}