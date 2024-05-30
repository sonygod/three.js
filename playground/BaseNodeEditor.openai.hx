package three.js.playground;

import flow.Node;
import flow.ButtonInput;
import flow.TitleElement;
import flow.ContextMenu;

class BaseNodeEditor extends Node {
    public var title:TitleElement;
    public var contextButton:ButtonInput;
    public var context:ContextMenu;
    public var editor:Dynamic;
    public var value:Dynamic;
    public var onValidElement:Dynamic->Dynamic->Void;
    public var outputLength:Float;

    public function new(name:String, ?value:Dynamic, width:Int = 300) {
        super();

        var getObjectCallback = function(?output:Dynamic) {
            return value;
        };

        setWidth(width);

        title = new TitleElement(name);
        title.setObjectCallback(getObjectCallback);
        title.setSerializable(false);
        setOutputAestheticsFromNode(title, value);

        contextButton = new ButtonInput();
        contextButton.onClick(function() {
            context.open();
        });
        contextButton.setIcon('ti ti-dots');

        var onAddButtons = function() {
            context.removeEventListener('show', onAddButtons);

            context.add(new ButtonInput('Remove').setIcon('ti ti-trash').onClick(function() {
                dispose();
            }));

            if (hasJSON()) {
                context.add(new ButtonInput('Export').setIcon('ti ti-download').onClick(function() {
                    exportJSON(exportJSON(), Type.getClassName(Type.getClass(this)));
                }));
            }

            context.add(new ButtonInput('Isolate').setIcon('ti ti-3d-cube-sphere').onClick(function() {
                context.hide();
                title.dom.dispatchEvent(new MouseEvent('dblclick'));
            }));
        };

        context = new ContextMenu(dom);
        context.addEventListener('show', onAddButtons);

        title.addButton(contextButton);

        add(title);

        editor = null;

        this.value = value;

        onValidElement = onValidNode;

        outputLength = getLengthFromNode(value);
    }

    public function getColor():String {
        var color = getColorFromNode(value);
        return color != null ? color + 'BB' : null;
    }

    public function hasJSON():Bool {
        return value != null && Reflect.hasField(value, 'toJSON');
    }

    public function exportJSON():Dynamic {
        return value.toJSON();
    }

    override public function serialize(data:Dynamic) {
        super.serialize(data);
        Reflect.deleteField(data, 'width');
    }

    override public function deserialize(data:Dynamic) {
        Reflect.deleteField(data, 'width');
        super.deserialize(data);
    }

    public function setEditor(value:Dynamic) {
        editor = value;
        dispatchEvent(new Event('editor'));
        return this;
    }

    override public function add(element:Node) {
        element.onValid(function(source:Node, target:Node) {
            onValidElement(source, target);
        });
        return super.add(element);
    }

    public function setName(value:String) {
        title.setTitle(value);
        return this;
    }

    public function setIcon(value:String) {
        title.setIcon('ti ti-' + value);
        return this;
    }

    public function getName():String {
        return title.getTitle();
    }

    public function setObjectCallback(callback:Dynamic->Void) {
        title.setObjectCallback(callback);
        return this;
    }

    public function getObject(callback:Dynamic->Void) {
        return title.getObject(callback);
    }

    public function setColor(color:String) {
        title.setColor(color);
        return this;
    }

    public function invalidate() {
        title.dispatchEvent(new Event('connect'));
    }

    override public function dispose() {
        setEditor(null);
        context.hide();
        super.dispose();
    }
}