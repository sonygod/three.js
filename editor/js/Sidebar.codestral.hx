import ui.UITabbedPanel;
import ui.UISpan;

import SidebarScene;
import SidebarProperties;
import SidebarProject;
import SidebarSettings;

class Sidebar {
    function new(editor:Editor) {
        this.editor = editor;
        this.init();
    }

    var editor:Editor;
    var container:UITabbedPanel;

    function init() {
        var strings = editor.strings;

        container = new UITabbedPanel();
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
    }
}