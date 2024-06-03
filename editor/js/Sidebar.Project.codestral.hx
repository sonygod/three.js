import js.html.UIElement;
import js.html.UIElementType;
import UISpan from './libs/ui';
import SidebarProjectApp from './Sidebar.Project.App';
import SidebarProjectRenderer from './Sidebar.Project.Renderer';
import SidebarProjectImage from './Sidebar.Project.Image';
import SidebarProjectVideo from './Sidebar.Project.Video';

class SidebarProject {
    public function new(editor: Dynamic) {
        var container: UISpan = new UISpan();

        container.add(new SidebarProjectRenderer(editor));

        container.add(new SidebarProjectApp(editor));

        container.add(new SidebarProjectImage(editor));

        if (js.Browser.window.hasOwnProperty("SharedArrayBuffer")) {
            container.add(new SidebarProjectVideo(editor));
        }

        return container;
    }
}