import three.js.editor.js.libs.ui.UITabbedPanel;
import three.js.editor.js.Sidebar.Object.SidebarObject;
import three.js.editor.js.Sidebar.Geometry.SidebarGeometry;
import three.js.editor.js.Sidebar.Material.SidebarMaterial;
import three.js.editor.js.Sidebar.Script.SidebarScript;

class SidebarProperties {

    public function new(editor:Dynamic) {

        var strings = editor.strings;

        var container = new UITabbedPanel();
        container.setId('properties');

        container.addTab('objectTab', strings.getKey('sidebar/properties/object'), new SidebarObject(editor));
        container.addTab('geometryTab', strings.getKey('sidebar/properties/geometry'), new SidebarGeometry(editor));
        container.addTab('materialTab', strings.getKey('sidebar/properties/material'), new SidebarMaterial(editor));
        container.addTab('scriptTab', strings.getKey('sidebar/properties/script'), new SidebarScript(editor));
        container.select('objectTab');

        function getTabByTabId(tabs:Array<Dynamic>, tabId:String):Dynamic {

            return Array.filter(tabs, function(tab) {

                return tab.dom.id === tabId;

            })[0];

        }

        var geometryTab = getTabByTabId(container.tabs, 'geometryTab');
        var materialTab = getTabByTabId(container.tabs, 'materialTab');
        var scriptTab = getTabByTabId(container.tabs, 'scriptTab');

        function toggleTabs(object:Dynamic) {

            container.setHidden(object === null);

            if (object === null) return;

            geometryTab.setHidden(!object.geometry);

            materialTab.setHidden(!object.material);

            scriptTab.setHidden(object === editor.camera);

            // set active tab

            if (container.selected === 'geometryTab') {

                container.select(geometryTab.isHidden() ? 'objectTab' : 'geometryTab');

            } else if (container.selected === 'materialTab') {

                container.select(materialTab.isHidden() ? 'objectTab' : 'materialTab');

            } else if (container.selected === 'scriptTab') {

                container.select(scriptTab.isHidden() ? 'objectTab' : 'scriptTab');

            }

        }

        editor.signals.objectSelected.add(toggleTabs);

        toggleTabs(editor.selected);

        return container;

    }

}