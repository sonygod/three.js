package three.js.editor.js.libs;

import js.html.Event;

class UIListbox extends UIDiv {
    
    public var items:Array<Dynamic>;
    public var listitems:Array<ListboxItem>;
    public var selectedIndex:Int;
    public var selectedValue:Null<String>;

    public function new() {
        super();
        this.dom.className = 'Listbox';
        this.dom.tabIndex = 0;
        this.items = [];
        this.listitems = [];
        this.selectedIndex = 0;
        this.selectedValue = null;
    }

    public function setItems(items:Array<Dynamic>) {
        if (items != null) {
            this.items = items;
        }
        this.render();
    }

    public function render() {
        while (this.listitems.length > 0) {
            var item = this.listitems.shift();
            item.dom.remove();
        }
        for (i in 0...this.items.length) {
            var item = this.items[i];
            var listitem = new ListboxItem(this);
            listitem.setId(item.id != null ? item.id : 'Listbox-$i');
            listitem.setTextContent(item.name != null ? item.name : item.type);
            this.add(listitem);
        }
    }

    public function add(...items:Array<ListboxItem>) {
        this.listitems = this.listitems.concat(items);
        UIElement.prototype.add.apply(this, items);
    }

    public function selectIndex(index:Int) {
        if (index >= 0 && index < this.items.length) {
            this.setValue(this.listitems[index].getId());
        }
        this.selectedIndex = index;
    }

    public function getValue():Null<String> {
        return this.selectedValue;
    }

    public function setValue(value:String) {
        for (i in 0...this.listitems.length) {
            var element = this.listitems[i];
            if (element.getId() == value) {
                element.addClass('active');
            } else {
                element.removeClass('active');
            }
        }
        this.selectedValue = value;
        var changeEvent = new Event('change', { bubbles: true, cancelable: true });
        this.dom.dispatchEvent(changeEvent);
    }
}