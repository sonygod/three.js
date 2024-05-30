import js.UITabbedPanel;
import js.UISpan;

import SidebarScene from './Sidebar.Scene.hx';
import SidebarProperties from './Sidebar.Properties.hx';
import SidebarProject from './Sidebar.Project.hx';
import SidebarSettings from './Sidebar.Settings.hx';

function Sidebar(editor) {
    let strings = editor.strings;
    let container = new UITabbedPanel();
    container.setId('sidebar');

    let scene = new UISpan();
    scene.add(new SidebarScene(editor));
    scene.add(new SidebarProperties(editor));

    container.addTab('scene', strings.getKey('sidebar/scene'), scene);
    container.addTab('project', strings.getKey('sidebar/project'), new SidebarProject(editor));
    container.addTab('settings', strings.getKey('sidebar/settings'), new SidebarSettings(editor));
    container.select('scene');

    return container;
}

export { Sidebar };