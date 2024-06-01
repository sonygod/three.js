import haxe.ds.ArraySort;
import js.Lib;
import ui.UITabbedPanel;

class SidebarProperties {

	public static function create(editor:Editor):UITabbedPanel {
		var strings = editor.strings;

		var container = new UITabbedPanel();
		container.setId('properties');

		container.addTab('objectTab', strings.getKey('sidebar/properties/object'), new SidebarObject(editor));
		container.addTab('geometryTab', strings.getKey('sidebar/properties/geometry'), new SidebarGeometry(editor));
		container.addTab('materialTab', strings.getKey('sidebar/properties/material'), new SidebarMaterial(editor));
		container.addTab('scriptTab', strings.getKey('sidebar/properties/script'), new SidebarScript(editor));
		container.select('objectTab');

		function getTabByTabId(tabs:Array<UITabbedPanel.Tab>, tabId:String):UITabbedPanel.Tab {
			return tabs.find(function(tab) {
				return tab.dom.id == tabId;
			});
		}

		var geometryTab = getTabByTabId(container.tabs, 'geometryTab');
		var materialTab = getTabByTabId(container.tabs, 'materialTab');
		var scriptTab = getTabByTabId(container.tabs, 'scriptTab');

		function toggleTabs(object:Dynamic) {
			container.setHidden(object == null);

			if (object == null) return;

			geometryTab.setHidden(!Reflect.hasField(object, 'geometry'));

			materialTab.setHidden(!Reflect.hasField(object, 'material'));

			scriptTab.setHidden(object == editor.camera);

			// set active tab
			switch (container.selected) {
				case 'geometryTab':
					container.select(geometryTab.isHidden() ? 'objectTab' : 'geometryTab');
				case 'materialTab':
					container.select(materialTab.isHidden() ? 'objectTab' : 'materialTab');
				case 'scriptTab':
					container.select(scriptTab.isHidden() ? 'objectTab' : 'scriptTab');
				default:
			}
		}

		editor.signals.objectSelected.add(toggleTabs);

		toggleTabs(editor.selected);

		return container;
	}
}