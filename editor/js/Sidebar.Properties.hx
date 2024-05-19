package three.js.editor.js;

import ui.UITabbedPanel;

class SidebarProperties {
    private var editor:Dynamic;
    private var strings:Dynamic;
    private var container:UITabbedPanel;
    private var geometryTab:Dynamic;
    private var materialTab:Dynamic;
    private var scriptTab:Dynamic;

    public function new(editor:Dynamic) {
        this.editor = editor;
        strings = editor.strings;

        container = new UITabbedPanel();
        container.setId('properties');

        container.addTab('objectTab', strings.getKey('sidebar/properties/object'), new SidebarObject(editor));
        container.addTab('geometryTab', strings.getKey('sidebar/properties/geometry'), new SidebarGeometry(editor));
        container.addTab('materialTab', strings.getKey('sidebar/properties/material'), new SidebarMaterial(editor));
        container.addTab('scriptTab', strings.getKey('sidebar/properties/script'), new SidebarScript(editor));
        container.select('objectTab');

        getTabByTabId = function(tabs:Array<Dynamic>, tabId:String):Dynamic {
            for (tab in tabs) {
                if (tab.dom.id == tabId) {
                    return tab;
                }
            }
            return null;
        }

        geometryTab = getTabByTabId(container.tabs, 'geometryTab');
        materialTab = getTabByTabId(container.tabs, 'materialTab');
        scriptTab = getTabByTabId(container.tabs, 'scriptTab');

        toggleTabs = function(object:Dynamic) {
            container.setHidden(object == null);

            if (object == null) return;

            geometryTab.setHidden(!object.geometry);
            materialTab.setHidden(!object.material);
            scriptTab.setHidden(object == editor.camera);

            // set active tab
            if (container.selected == 'geometryTab') {
                container.select(geometryTab.isHidden() ? 'objectTab' : 'geometryTab');
            } else if (container.selected == 'materialTab') {
                container.select(materialTab.isHidden() ? 'objectTab' : 'materialTab');
            } else if (container.selected == 'scriptTab') {
                container.select(scriptTab.isHidden() ? 'objectTab' : 'scriptTab');
            }
        }

        editor.signals.objectSelected.add(toggleTabs);
        toggleTabs(editor.selected);
    }
}