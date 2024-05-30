import js.Browser.Dom;
import js.Browser.Window;

class SidebarProperties {
    public function new(editor:Editor) {
        var container = js.Browser.Dom.createElement('div');
        container.id = 'properties';

        var objectTab = js.Browser.Dom.createElement('div');
        objectTab.id = 'objectTab';
        var geometryTab = js.Browser.Dom.createElement('div');
        geometryTab.id = 'geometryTab';
        var materialTab = js.Browser.Dom.createElement('div');
        materialTab.id = 'materialTab';
        var scriptTab = js.Browser.Dom.createElement('div');
        scriptTab.id = 'scriptTab';

        var tabs = [objectTab, geometryTab, materialTab, scriptTab];

        function getTabById(tabId:String):Dynamic {
            return tabs.filter($tab -> $tab.id == tabId)[0];
        }

        function toggleTabs(object:Dynamic) {
            if (object == null) {
                container.style.display = 'none';
                return;
            }

            container.style.display = 'block';

            geometryTab.style.display = if (object.geometry) 'block' else 'none';
            materialTab.style.display = if (object.material) 'block' else 'none';
            scriptTab.style.display = if (object == editor.camera) 'none' else 'block';

            var activeTab = getTabById(editor.selectedTab);
            if (activeTab != null) {
                activeTab.className = '';
            }

            activeTab = getTabById('objectTab');
            if (activeTab != null && activeTab.style.display != 'none') {
                activeTab.className = 'active';
            }

            activeTab = getTabById('geometryTab');
            if (activeTab != null && activeTab.style.display != 'none') {
                activeTab.className = 'active';
            }

            activeTab = getTabById('materialTab');
            if (activeTab != null && activeTab.style.display != 'none') {
                activeTab.className = 'active';
            }

            activeTab = getTabById('scriptTab');
            if (activeTab != null && activeTab.style.display != 'none') {
                activeTab.className = 'active';
            }
        }

        editor.signals.objectSelected.add(toggleTabs);

        toggleTabs(editor.selected);

        return container;
    }
}