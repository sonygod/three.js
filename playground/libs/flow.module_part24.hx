package three.js.playground.libs;

import js.html.Document;
import js.html.Element;
import js.Browser;

class TreeViewNode {
  public var dom:Element;
  public var childrenDOM:Element;
  public var labelSpam:Element;
  public var labelDOM:Element;
  public var inputDOM:Element;
  public var iconDOM:Element;
  public var parent:TreeViewNode;
  public var children:Array<TreeViewNode>;
  public var selected:Bool;
  public var events:Dynamic;

  public function new(name:String = '') {
    var dom:Element = Browser.document.createElement('f-treeview-node');
    var labelDOM:Element = Browser.document.createElement('f-treeview-label');
    var inputDOM:Element = Browser.document.createElement('input');

    var labelSpam:Element = Browser.document.createElement('spam');
    labelDOM.appendChild(labelSpam);

    labelSpam.innerText = name;

    inputDOM.type = 'checkbox';

    dom.appendChild(inputDOM);
    dom.appendChild(labelDOM);

    this.dom = dom;
    this.childrenDOM = null;
    this.labelSpam = labelSpam;
    this.labelDOM = labelDOM;
    this.inputDOM = inputDOM;
    this.iconDOM = null;

    this.parent = null;
    this.children = [];

    this.selected = false;

    this.events = {
      'change': [],
      'click': []
    };

    dom.addEventListener('click', function(_) {
      dispatchEventList(this.events.click, this);
    });
  }

  public function setLabel(value:String):TreeViewNode {
    this.labelSpam.innerText = value;
    return this;
  }

  public function getLabel():String {
    return this.labelSpam.innerText;
  }

  public function add(node:TreeViewNode):TreeViewNode {
    var childrenDOM:Element = this.childrenDOM;

    if (this.childrenDOM === null) {
      var dom:Element = this.dom;

      var arrowDOM:Element = Browser.document.createElement('f-arrow');
      childrenDOM = Browser.document.createElement('f-treeview-children');

      dom.appendChild(arrowDOM);
      dom.appendChild(childrenDOM);

      this.childrenDOM = childrenDOM;
    }

    this.children.push(node);
    childrenDOM.appendChild(node.dom);

    node.parent = this;

    return this;
  }

  public function setOpened(value:Bool):TreeViewNode {
    this.inputDOM.checked = value;
    return this;
  }

  public function getOpened():Bool {
    return this.inputDOM.checked;
  }

  public function setIcon(value:String):TreeViewNode {
    this.iconDOM = this.iconDOM || Browser.document.createElement('i');
    this.iconDOM.className = value;

    if (value != null) this.labelDOM.prepend(this.iconDOM);
    else this.iconDOM.remove();

    return this;
  }

  public function getIcon():String {
    return this.iconDOM != null ? this.iconDOM.className : null;
  }

  public function setVisible(value:Bool):TreeViewNode {
    this.dom.style.display = value ? '' : 'none';
    return this;
  }

  public function setSelected(value:Bool):TreeViewNode {
    if (this.selected == value) return this;

    if (value) this.dom.classList.add('selected');
    else this.dom.classList.remove('selected');

    this.selected = value;

    return this;
  }

  public function onClick(callback:TreeViewNode->Void):TreeViewNode {
    this.events.click.push(callback);
    return this;
  }
}