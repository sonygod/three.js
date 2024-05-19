package three.js.editor.js.libs;

import js.html.SelectElement;
import js.html.OptionElement;
import js.html.Document;
import js.Browser;

class UISelect extends UIElement {
    
    public function new() {
        super(Browser.document.createElement("select"));
        
        this.dom.className = 'Select';
        this.dom.style.padding = '2px';
        
        this.dom.setAttribute('autocomplete', 'off');
        
        this.dom.addEventListener('pointerdown', function(event) {
            event.stopPropagation();
        });
    }
    
    public function setMultiple(boolean:Bool) {
        this.dom.multiple = boolean;
        return this;
    }
    
    public function setOptions(options:Dynamic) {
        var selected = this.dom.value;
        
        while (this.dom.children.length > 0) {
            this.dom.removeChild(this.dom.firstChild);
        }
        
        for (key in Reflect.fields(options)) {
            var option = Browser.document.createElement("option");
            option.value = key;
            option.innerHTML = options[key];
            this.dom.appendChild(option);
        }
        
        this.dom.value = selected;
        return this;
    }
    
    public function getValue() {
        return this.dom.value;
    }
    
    public function setValue(value:String) {
        if (this.dom.value != value) {
            this.dom.value = value;
        }
        return this;
    }
}