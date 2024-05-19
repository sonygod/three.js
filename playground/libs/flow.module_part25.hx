package three.js.playground.libs;

import js.html.Document;
import js.html.Element;

class TreeViewInput extends Input {
    private var childrenDOM:Element;
    private var children:Array<Dynamic>;

    public function new(options:Array<Dynamic> = []) {
        var dom:Element = Document.createElement('f-treeview');
        super(dom);

        childrenDOM = Document.createElement('f-treeview-children');
        dom.appendChild(childrenDOM);

        dom.setAttribute('type', 'tree');

        children = [];

        // Note: In Haxe, we don't need to use `this` to access class members
        //       We can access them directly using their names
    }

    public function add(node:Dynamic):TreeViewInput {
        children.push(node);
        childrenDOM.appendChild(node.dom);

        return this;
    }

    public function serialize(data:Dynamic):Void {
        //data.options = [ ...options ]; // Note: options is not defined in this class
        super.serialize(data);
    }

    public function deserialize(data:Dynamic):Void {
        /*var currentOptions:Array<Dynamic> = options;
        if (currentOptions.length === 0) {
            setOptions(data.options);
        }*/
        super.deserialize(data);
    }
}