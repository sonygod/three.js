import ui.UITabbedPanel;
import SidebarObject;
import SidebarGeometry;
import SidebarMaterial;
import SidebarScript;

class SidebarProperties {

	public function new(editor:Editor) {

		var strings = editor.strings;

		var container:UITabbedPanel = new UITabbedPanel();
		container.setId('properties');

		container.addTab('objectTab', strings.getKey('sidebar/properties/object'), new SidebarObject(editor));
		container.addTab('geometryTab', strings.getKey('sidebar/properties/geometry'), new SidebarGeometry(editor));
		container.addTab('materialTab', strings.getKey('sidebar/properties/material'), new SidebarMaterial(editor));
		container.addTab('scriptTab', strings.getKey('sidebar/properties/script'), new SidebarScript(editor));
		container.select('objectTab');

		var geometryTab = container.tabs.find(function(tab) {
			return tab.dom.id === 'geometryTab';
		});

		var materialTab = container.tabs.find(function(tab) {
			return tab.dom.id === 'materialTab';
		});

		var scriptTab = container.tabs.find(function(tab) {
			return tab.dom.id === 'scriptTab';
		});

		var toggleTabs = function(object:Object) {

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
		};

		editor.signals.objectSelected.add(toggleTabs);

		toggleTabs(editor.selected);

		return container;

	}

}