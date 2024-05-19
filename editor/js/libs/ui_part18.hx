package three.js.editor.js.libs;

import js.html.DivElement;
import js.Browser;

class UITabbedPanel extends UIDiv {
    public var tabs:Array<UITab> = [];
    public var panels:Array<UIDiv> = [];
    public var tabsDiv:UIDiv;
    public var panelsDiv:UIDiv;
    public var selected:String = '';

    public function new() {
        super();

        this.dom.className = 'TabbedPanel';

        tabsDiv = new UIDiv();
        tabsDiv.setClass('Tabs');
        this.add(tabsDiv);

        panelsDiv = new UIDiv();
        panelsDiv.setClass('Panels');
        this.add(panelsDiv);
    }

    public function select(id:String) {
        var tab:UITab = null;
        var panel:UIDiv = null;
        var scope:UIPanel = this;

        // Deselect current selection
        if (selected != null && selected.length > 0) {
            tab = Lambda.find(tabs, function(item) {
                return item.dom.id == scope.selected;
            });
            panel = Lambda.find(panels, function(item) {
                return item.dom.id == scope.selected;
            });

            if (tab != null) {
                tab.removeClass('selected');
            }

            if (panel != null) {
                panel.setDisplay('none');
            }
        }

        tab = Lambda.find(tabs, function(item) {
            return item.dom.id == id;
        });
        panel = Lambda.find(panels, function(item) {
            return item.dom.id == id;
        });

        if (tab != null) {
            tab.addClass('selected');
        }

        if (panel != null) {
            panel.setDisplay('');
        }

        selected = id;

        return this;
    }

    public function addTab(id:String, label:String, items:Array<Dynamic>) {
        var tab:UITab = new UITab(label, this);
        tab.setId(id);
        tabs.push(tab);
        tabsDiv.add(tab);

        var panel:UIDiv = new UIDiv();
        panel.setId(id);
        panel.add(items);
        panel.setDisplay('none');
        panels.push(panel);
        panelsDiv.add(panel);

        this.select(id);
    }
}