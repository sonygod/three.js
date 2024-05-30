import Node.{Node, ButtonInput, TitleElement, ContextMenu} from 'flow';
import {exportJSON, onValidNode} from './NodeEditorUtils.hx';
import {setOutputAestheticsFromNode, getColorFromNode, getLengthFromNode} from './DataTypeLib.hx';

class BaseNodeEditor extends Node {

	public var value:Dynamic;
	public var editor:Dynamic;
	public var contextButton:ButtonInput;
	public var context:ContextMenu;
	public var title:TitleElement;

	public function new(name:String, value:Dynamic = null, width:Int = 300) {

		super();

		var getObjectCallback = function(/*output = null*/) {

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

					exportJSON(this.exportJSON(), Type.getClassName(Type.getClass(this)));

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

		var color = getColorFromNode(this.value);

		return color != null ? color + 'BB' : null;

	}

	public function hasJSON():Bool {

		return this.value != null && Reflect.hasField(this.value, 'toJSON');

	}

	public function exportJSON():Dynamic {

		return Reflect.callMethod(this.value, 'toJSON', []);

	}

	@:override
	public function serialize(data:Dynamic) {

		super.serialize(data);

		untyped delete(data).width;

	}

	@:override
	public function deserialize(data:Dynamic) {

		untyped delete(data).width;

		super.deserialize(data);

	}

	public function setEditor(value:Dynamic):BaseNodeEditor {

		this.editor = value;

		this.dispatchEvent(new Event('editor'));

		return this;

	}

	@:override
	public function add(element:Dynamic):Dynamic {

		element.onValid(function(source:Dynamic, target:Dynamic) this.onValidElement(source, target));

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

	@:override
	public function dispose():Void {

		this.setEditor(null);

		this.context.hide();

		super.dispose();

	}

}