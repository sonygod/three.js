package three.js.editor.js.libs;

import js.html.InputElement;
import js.html.Document;

class UIColor extends UIElement {
    
    public function new() {
        super(cast Document.createElement('input'));
        
        dom.className = 'Color';
        dom.style.width = '32px';
        dom.style.height = '16px';
        dom.style.border = '0px';
        dom.style.padding = '2px';
        dom.style.backgroundColor = 'transparent';
        
        dom.setAttribute('autocomplete', 'off');
        
        try {
            untyped __js__("this.dom.type = 'color';");
            dom.value = '#ffffff';
        } catch (e:Dynamic) {}
    }
    
    public function getValue():String {
        return dom.value;
    }
    
    public function getHexValue():Int {
        return Std.parseInt(dom.value.substring(1), 16);
    }
    
    public function setValue(value:String):UIColor {
        dom.value = value;
        return this;
    }
    
    public function setHexValue(hex:Int):UIColor {
        dom.value = '#' + StringTools.lpad(Std.string(hex), '0', 6);
        return this;
    }
}