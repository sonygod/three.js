import SidebarProjectApp from "./SidebarProjectApp.hx";
import SidebarProjectImage from "./SidebarProjectImage.hx";
import SidebarProjectRenderer from "./SidebarProjectRenderer.hx";
import SidebarProjectVideo from "./SidebarProjectVideo.hx";

function sidebarProject(editor:Editor) {
    var container = new UISpan();

    container.add(new SidebarProjectRenderer(editor));
    container.add(new SidebarProjectApp(editor));
    container.add(new SidebarProjectImage(editor));

    if (Reflect.field(window, "SharedArrayBuffer")) {
        container.add(new SidebarProjectVideo(editor));
    }

    return container;
}

class SidebarProject {
    public static sidebarProject = sidebarProject;
}

export default SidebarProject;