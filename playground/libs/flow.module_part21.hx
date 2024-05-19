package three.js.playground.libs;

import js.html.Document;
import js.html.Element;
import js.html.InputElement;
import js.html.OptionElement;
import js.html.DataListElement;
import js.Browser;

class StringInput extends Input {
  private var inputDOM:InputElement;
  private var buttonsDOM:Element;
  private var datalistDOM:DataListElement;
  private var iconDOM:Element;
  private var buttons:Array<Dynamic>;

  public function new(?value:String = '') {
    super(createDom());
    inputDOM = Browser.document.createInputElement();
    inputDOM.type = 'text';
    inputDOM.value = value;
    inputDOM.spellcheck = false;
    inputDOM.autocomplete = 'off';

    dom.appendChild(inputDOM);

    buttonsDOM = null;
    datalistDOM = null;
    iconDOM = null;
    buttons = [];

    inputDOM.onblur = function() {
      dispatchEvent(new Event('blur'));
    };

    inputDOM.onchange = function() {
      dispatchEvent(new Event('change'));
    };

    var keyDownStr:String = '';

    inputDOM.onkeydown = function() {
      keyDownStr = inputDOM.value;
    };

    inputDOM.onkeyup = function(e) {
      if (e.key == 'Enter') {
        e.target.blur();
      }
      e.stopPropagation();
      if (keyDownStr != inputDOM.value) {
        dispatchEvent(new Event('change'));
      }
    };
  }

  public function setPlaceHolder(text:String):StringInput {
    inputDOM.placeholder = text;
    return this;
  }

  public function setIcon(value:String):StringInput {
    if (iconDOM == null) {
      iconDOM = Browser.document.createElement('i');
      iconDOM.setAttribute('type', 'icon');
    }
    iconDOM.className = value;
    if (value != null) {
      dom.prepend(iconDOM);
    } else {
      iconDOM.remove();
    }
    return this;
  }

  public function getIcon():String {
    return iconInput != null ? iconInput.getIcon() : '';
  }

  public function addButton(button:Dynamic):StringInput {
    buttonsDOM.prepend(button.iconDOM);
    buttons.push(button);
    return this;
  }

  public function addOption(value:String):StringInput {
    var option:OptionElement = Browser.document.createOptionElement();
    option.value = value;
    datalistDOM.appendChild(option);
    return this;
  }

  public function clearOptions():Void {
    datalistDOM.remove();
  }

  private function createDom():Element {
    var dom:Element = Browser.document.createElement('f-string');
    return dom;
  }

  private function get_datalistDOM():DataListElement {
    if (datalistDOM == null) {
      var datalistId:String = 'input-dt-' + id;
      datalistDOM = Browser.document.createElement('datalist');
      datalistDOM.id = datalistId;
      inputDOM.autocomplete = 'on';
      inputDOM.setAttribute('list', datalistId);
      dom.prepend(datalistDOM);
    }
    return datalistDOM;
  }

  private function get_buttonsDOM():Element {
    if (buttonsDOM == null) {
      buttonsDOM = Browser.document.createElement('f-buttons');
      dom.prepend(buttonsDOM);
    }
    return buttonsDOM;
  }

  public function getInput():InputElement {
    return inputDOM;
  }
}