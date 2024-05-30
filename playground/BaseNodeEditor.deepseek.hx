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

	public function new(name:String, value:Dynamic = null, width:Int = 300) {

		super();

		var getObjectCallback = function(output:Dynamic = null) {

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

				this.context.add(new ButtonInput('Export').setIcon('ti ti-download').onClick(function() {

					exportJSON(this.exportJSON(), this.constructor.name);

				}));

			}

			context.add(new ButtonInput('Isolate').setIcon('ti ti-3d-cube-sphere').onClick(function() {

				this.context.hide();

				this.title.dom.dispatchEvent(new MouseEvent('dblclick'));

			}));

		};

		var context = new ContextMenu(this.dom);
		context.addEventListener('show', onAddButtons);

		this.title = title;

		if (this.icon) this.setIcon('ti ti-' + this.icon);

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

		var color = getColorFromNode(this.value);

		return color ? color + 'BB' : null;

	}

	public function hasJSON():Bool {

		return this.value && typeof this.value.toJSON === 'function';

	}

	public function exportJSON():Dynamic {

		return this.value.toJSON();

	}

	public function serialize(data:Dynamic):Void {

		super.serialize(data);

		delete data.width;

	}

	public function deserialize(data:Dynamic):Void {

		delete data.width;

		super.deserialize(data);

	}

	public function setEditor(value:Dynamic):BaseNodeEditor {

		this.editor = value;

		this.dispatchEvent(new Event('editor'));

		return this;

	}

	public function add(element:Dynamic):BaseNodeEditor {

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

	public function setObjectCallback(callback:Dynamic->Dynamic):BaseNodeEditor {

		this.title.setObjectCallback(callback);

		return this;

	}

	public function getObject(callback:Dynamic->Dynamic):Dynamic {

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