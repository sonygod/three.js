package three.js.playground;

import flow.Node;
import flow.input.ButtonInput;
import flow.element.TitleElement;
import flow.menu.ContextMenu;
import NodeEditorUtils.exportJSON;
import NodeEditorUtils.onValidNode;
import DataTypeLib.setOutputAestheticsFromNode;
import DataTypeLib.getColorFromNode;
import DataTypeLib.getLengthFromNode;

class BaseNodeEditor extends Node {
    public function new(name:String, ?value:Dynamic, width:Int = 300) {
        super();
        var getObjectCallback = function(?output:Dynamic) {
            return value;
        };

        this.setWidth(width);

        var title = new TitleElement(name);
        title.setObjectCallback(getObjectCallback);
        title.setSerializable(false);
        setOutputAestheticsFromNode(title, value);

        var contextButton = new ButtonInput();
        contextButton.onClick(function() {
            context.open();
        });
        contextButton.setIcon('ti ti-dots');

        var onAddButtons = function() {
            context.removeEventListener('show', onAddButtons);

            context.add(new ButtonInput('Remove').setIcon('ti ti-trash').onClick(function() {
                this.dispose();
            }));

            if (this.hasJSON()) {
                context.add(new ButtonInput('Export').setIcon('ti ti-download').onClick(function() {
                    exportJSON(this.exportJSON(), Type.getClassName(Type.getClass(this)));
                }));
            }

            context.add(new ButtonInput('Isolate').setIcon('ti ti-3d-cube-sphere').onClick(function() {
                context.hide();
                title.dom.dispatchEvent(new MouseEvent('dblclick'));
            }));
        };

        var context = new ContextMenu(this.dom);
        context.addEventListener('show', onAddButtons);

        this.title = title;

        if (this.icon != null) this.setIcon('ti ti-' + this.icon);

        this.contextButton = contextButton;
        this.context = context;

        title.addButton(contextButton);

        this.add(title);

        this.editor = null;

        this.value = value;

        this.onValidElement = onValidNode;

        this.outputLength = getLengthFromNode(value);
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
        this.editor = value;
        this.dispatchEvent(new Event('editor'));
        return this;
    }

    override public function add(element:Node) {
        element.onValid.add(function(source:Node, target:Node) {
            onValidNode(source, target);
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

    public function setObjectCallback(callback:Dynamic) {
        title.setObjectCallback(callback);
        return this;
    }

    public function getObject(callback:Dynamic) {
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