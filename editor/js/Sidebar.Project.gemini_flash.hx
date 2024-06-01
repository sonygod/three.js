import js.Lib.Uint8Array;

import ui.UISpan;

import SidebarProjectApp from './Sidebar.Project.App';
// import SidebarProjectMaterials from './Sidebar.Project.Materials';
import SidebarProjectRenderer from './Sidebar.Project.Renderer';
import SidebarProjectImage from './Sidebar.Project.Image';
import SidebarProjectVideo from './Sidebar.Project.Video';

class SidebarProject {

    public static function create(editor: Dynamic) {

        var container = new UISpan();

        container.add(new SidebarProjectRenderer(editor));

        // container.add( new SidebarProjectMaterials( editor ) );

        container.add(new SidebarProjectApp(editor));

        container.add(new SidebarProjectImage(editor));

        if (untyped __js__("typeof SharedArrayBuffer !== 'undefined'")) {

            container.add(new SidebarProjectVideo(editor));

        }

        return container;

    }

}