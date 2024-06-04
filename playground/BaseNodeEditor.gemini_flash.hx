import flow.Node;
import flow.ButtonInput;
import flow.TitleElement;
import flow.ContextMenu;
import NodeEditorUtils.exportJSON;
import NodeEditorUtils.onValidNode;
import DataTypeLib.setOutputAestheticsFromNode;
import DataTypeLib.getColorFromNode;
import DataTypeLib.getLengthFromNode;

class BaseNodeEditor extends Node {

	public var value:Dynamic;
	public var editor:Dynamic;
	public var context:ContextMenu;
	public var contextButton:ButtonInput;
	public var title:TitleElement;
	public var icon:String;
	public var outputLength:Int;

	public function new(name:String, value:Dynamic = null, width:Int = 300) {
		super();

		this.setWidth(width);

		final getObjectCallback = function(?output:Dynamic):Dynamic {
			return this.value;
		};

		this.title = new TitleElement(name)
			.setObjectCallback(getObjectCallback)
			.setSerializable(false);

		setOutputAestheticsFromNode(this.title, value);

		this.contextButton = new ButtonInput().onClick(function() {
			this.context.open();
		}).setIcon('ti ti-dots');

		final onAddButtons = function() {
			this.context.removeEventListener('show', onAddButtons);

			this.context.add(new ButtonInput('Remove').setIcon('ti ti-trash').onClick(function() {
				this.dispose();
			}));

			if (this.hasJSON()) {
				this.context.add(new ButtonInput('Export').setIcon('ti ti-download').onClick(function() {
					exportJSON(this.exportJSON(), this.constructor.name);
				}));
			}

			this.context.add(new ButtonInput('Isolate').setIcon('ti ti-3d-cube-sphere').onClick(function() {
				this.context.hide();
				this.title.dom.dispatchEvent(new MouseEvent('dblclick'));
			}));
		};

		this.context = new ContextMenu(this.dom);
		this.context.addEventListener('show', onAddButtons);

		if (this.icon != null) this.setIcon('ti ti-' + this.icon);

		this.title.addButton(this.contextButton);
		this.add(this.title);

		this.value = value;

		this.onValidElement = onValidNode;

		this.outputLength = getLengthFromNode(value);
	}

	public function getColor():String {
		final color = getColorFromNode(this.value);
		return color != null ? color + 'BB' : null;
	}

	public function hasJSON():Bool {
		return this.value != null && Std.is(this.value.toJSON, Function);
	}

	public function exportJSON():Dynamic {
		return this.value.toJSON();
	}

	override public function serialize(data:Dynamic) {
		super.serialize(data);
		Reflect.deleteField(data, "width");
	}

	override public function deserialize(data:Dynamic) {
		Reflect.deleteField(data, "width");
		super.deserialize(data);
	}

	public function setEditor(value:Dynamic):BaseNodeEditor {
		this.editor = value;
		this.dispatchEvent(new Event('editor'));
		return this;
	}

	override public function add(element:Dynamic):Dynamic {
		element.onValid(function(source:Dynamic, target:Dynamic) {
			this.onValidElement(source, target);
		});
		return super.add(element);
	}

	public function setName(value:String):BaseNodeEditor {
		this.title.setTitle(value);
		return this;
	}

	public function setIcon(value:String):BaseNodeEditor {
		this.title.setIcon('ti ti-' + value);
		return this;
	}

	public function getName():String {
		return this.title.getTitle();
	}

	public function setObjectCallback(callback:Dynamic):BaseNodeEditor {
		this.title.setObjectCallback(callback);
		return this;
	}

	public function getObject(callback:Dynamic):Dynamic {
		return this.title.getObject(callback);
	}

	public function setColor(color:String):BaseNodeEditor {
		this.title.setColor(color);
		return this;
	}

	public function invalidate():Void {
		this.title.dispatchEvent(new Event('connect'));
	}

	public function dispose():Void {
		this.setEditor(null);
		this.context.hide();
		super.dispose();
	}
}