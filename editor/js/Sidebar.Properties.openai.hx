package three.js.editor.js;

import ui.UITabbedPanel;

import SidebarObject;
import SidebarGeometry;
import SidebarMaterial;
import SidebarScript;

class SidebarProperties {
    private var editor:Dynamic;
    private var container:UITabbedPanel;
    private var strings:Dynamic;

    public function new(editor:Dynamic) {
        this.editor = editor;
        this.strings = editor.strings;

        container = new UITabbedPanel();
        container.setId('properties');

        container.addTab('objectTab', strings.getKey('sidebar/properties/object'), new SidebarObject(editor));
        container.addTab('geometryTab', strings.getKey('sidebar/properties/geometry'), new SidebarGeometry(editor));
        container.addTab('materialTab', strings.getKey('sidebar/properties/material'), new SidebarMaterial(editor));
        container.addTab('scriptTab', strings.getKey('sidebar/properties/script'), new SidebarScript(editor));
        container.select('objectTab');

        var geometryTab = getTabByTabId(container.tabs, 'geometryTab');
        var materialTab = getTabByTabId(container.tabs, 'materialTab');
        var scriptTab = getTabByTabId(container.tabs, 'scriptTab');

        toggleTabs(editor.selected);

        editor.signals.objectSelected.add(toggleTabs);
    }

    private function getTabByTabId(tabs:Array<Dynamic>, tabId:String) {
        for (tab in tabs) {
            if (tab.dom.id == tabId) {
                return tab;
            }
        }
        return null;
    }

    private function toggleTabs(object:Dynamic) {
        container.setHidden(object == null);

        if (object == null) return;

        geometryTab.setHidden(!object.geometry);
        materialTab.setHidden(!object.material);
        scriptTab.setHidden(object == editor.camera);

        if (container.selected == 'geometryTab' && geometryTab.isHidden()) {
            container.select('objectTab');
        } else if (container.selected == 'materialTab' && materialTab.isHidden()) {
            container.select('objectTab');
        } else if (container.selected == 'scriptTab' && scriptTab.isHidden()) {
            container.select('objectTab');
        }
    }
}