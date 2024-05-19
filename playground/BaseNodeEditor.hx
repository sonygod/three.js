package three.js.playground;

import flow.Node;
import flow.ButtonInput;
import flow.TitleElement;
import flow.ContextMenu;

class BaseNodeEditor extends Node {
    public function new(name:String, value:Dynamic = null, width:Int = 300) {
        super();
        
        var getObjectCallback = function(/*output:Dynamic = null*/) {
            return this.value;
        };

        this.setWidth(width);

        var title = new TitleElement(name)
            .setObjectCallback(getObjectCallback)
            .setSerializable(false);
        
        setOutputAestheticsFromNode(title, value);

        var contextButton = new ButtonInput().onClick(function() {
            context.open();
        }).setIcon('ti ti-dots');

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
                title.dom.dispatchEvent(new js.html.MouseEvent('dblclick'));
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

    public function getColor():Null<String> {
        var color = getColorFromNode(this.value);
        return color != null ? color + 'BB' : null;
    }

    public function hasJSON():Bool {
        return this.value != null && Reflect.hasField(this.value, 'toJSON');
    }

    public function exportJSON():Dynamic {
        return this.value.toJSON();
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
        this.dispatchEvent(new js.html.Event('editor'));
        return this;
    }

    override public function add(element:Dynamic) {
        element.onValid(function(source:Dynamic, target:Dynamic) {
            onValidNode(source, target);
        });
        return super.add(element);
    }

    public function setName(value:String) {
        this.title.setTitle(value);
        return this;
    }

    public function setIcon(value:String) {
        this.title.setIcon('ti ti-' + value);
        return this;
    }

    public function getName():String {
        return this.title.getTitle();
    }

    public function setObjectCallback(callback:Dynamic) {
        this.title.setObjectCallback(callback);
        return this;
    }

    public function getObject(callback:Dynamic) {
        return this.title.getObject(callback);
    }

    public function setColor(color:String) {
        this.title.setColor(color);
        return this;
    }

    public function invalidate() {
        this.title.dispatchEvent(new js.html.Event('connect'));
    }

    override public function dispose() {
        this.setEditor(null);
        this.context.hide();
        super.dispose();
    }
}