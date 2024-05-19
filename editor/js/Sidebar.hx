package three.js.editor.js;

import js.lib.ui.UITabbedPanel;
import js.lib.ui.UISpan;

import SidebarScene from './Sidebar.Scene';
import SidebarProperties from './Sidebar.Properties';
import SidebarProject from './Sidebar.Project';
import SidebarSettings from './Sidebar.Settings';

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