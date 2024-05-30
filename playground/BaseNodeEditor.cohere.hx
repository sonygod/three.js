package;

import js.Browser.MouseEvent;
import js.html.Event;

import flow.Node;
import flow.ButtonInput;
import flow.TitleElement;
import flow.ContextMenu;

import DataTypeLib.setOutputAestheticsFromNode;
import DataTypeLib.getColorFromNode;
import DataTypeLib.getLengthFromNode;
import NodeEditorUtils.exportJSON;
import NodeEditorUtils.onValidNode;

@:allow(nullAccess)

class BaseNodeEditor extends Node {
    public var contextButton:ButtonInput;
    public var context:ContextMenu;
    public var title:TitleElement;
    public var editor:Dynamic;
    public var value:Dynamic;
    public var onValidElement:Dynamic->Dynamic->Void;
    public var outputLength:Int;

    public function new(name:String, value:Dynamic = null, width:Int = 300) {
        super();

        var getObjectCallback = function():Dynamic {
            return value;
        };

        setWidth(width);

        title = new TitleElement(name)
            .setObjectCallback(getObjectCallback)
            .setSerializable(false);

        setOutputAestheticsFromNode(title, value);

        contextButton = new ButtonInput().onClick(function() {
            context.open();
        }).setIcon('ti ti-dots');

        var onAddButtons = function() {
            context.removeEventListener('show', onAddButtons);

            context.add(new ButtonInput('Remove').setIcon('ti ti-trash').onClick(function() {
                dispose();
            }));

            if (hasJSON()) {
                context.add(new ButtonInput('Export').setIcon('ti ti-download').onClick(function() {
                    exportJSON(exportJSON(), $getTypeName());
                }));
            }

            context.add(new ButtonInput('Isolate').setIcon('ti ti-3d-cube-sphere').onClick(function() {
                context.hide();
                title.dom.dispatchEvent(new MouseEvent('dblclick'));
            }));
        };

        context = new ContextMenu(dom);
        context.addEventListener('show', onAddButtons);

        this.title = title;

        if (icon != null) {
            setIcon('ti ti-' + icon);
        }

        this.contextButton = contextButton;
        this.context = context;

        title.addButton(contextButton);

        add(title);

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

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.width = null;
    }

    public function deserialize(data:Dynamic) {
        data.width = null;
        super.deserialize(data);
    }

    public function setEditor(value:Dynamic):BaseNodeEditor {
        editor = value;
        dispatchEvent(new Event('editor'));
        return this;
    }

    public function add(element:Dynamic):BaseNodeEditor {
        element.onValid = function(source:Dynamic, target:Dynamic):Void {
            onValidElement(source, target);
        };
        return super.add(element);
    }

    public function setName(value:String):BaseNodeEditor {
        title.setTitle(value);
        return this;
    }

    public function setIcon(value:String):BaseNodeEditor {
        title.setIcon('ti ti-' + value);
        return this;
    }

    public function getName():String {
        return title.getTitle();
    }

    public function setObjectCallback(callback:Dynamic):BaseNodeEditor {
        title.setObjectCallback(callback);
        return this;
    }

    public function getObject(callback:Dynamic):BaseNodeEditor {
        return title.getObject(callback);
    }

    public function setColor(color:String):BaseNodeEditor {
        title.setColor(color);
        return this;
    }

    public function invalidate():Void {
        title.dispatchEvent(new Event('connect'));
    }

    public function dispose():Void {
        setEditor(null);
        context.hide();
        super.dispose();
    }
}