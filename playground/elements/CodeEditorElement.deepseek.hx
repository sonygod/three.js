import flow.Element;
import flow.LoaderLib;

class CodeEditorElement extends Element {

	public var updateInterval:Int = 500;
	private var _source:String;

	public function new(source:String = '') {
		super();

		this._source = source;

		this.dom.style['z-index'] = -1;
		this.dom.classList.add('no-zoom');

		this.setHeight(500);

		var editorDOM = js.Browser.document.createElement('div');
		editorDOM.style.width = '100%';
		editorDOM.style.height = '100%';
		this.dom.appendChild(editorDOM);

		var editor:Dynamic = null; // async

		js.Lib.require(['vs/editor/editor.main'], () -> {
			editor = js.Browser.window.monaco.editor.create(editorDOM, {
				value: this._source,
				language: 'javascript',
				theme: 'vs-dark',
				automaticLayout: true,
				minimap: { enabled: false }
			});

			var timeout:Dynamic = null;

			editor.getModel().onDidChangeContent(() -> {
				this._source = editor.getValue();

				if (timeout) clearTimeout(timeout);

				timeout = setTimeout(() -> {
					this.dispatchEvent(new Event('change'));
				}, this.updateInterval);
			});
		});

		this.editor = editor;
	}

	public function set source(value:String):Void {
		if (this._source == value) return;

		this._source = value;

		if (this.editor) this.editor.setValue(value);

		this.dispatchEvent(new Event('change'));
	}

	public function get source():String {
		return this._source;
	}

	public function focus():Void {
		if (this.editor) this.editor.focus();
	}

	public function serialize(data:Dynamic):Void {
		super.serialize(data);

		data.source = this.source;
	}

	public function deserialize(data:Dynamic):Void {
		super.deserialize(data);

		this.source = data.source || '';
	}
}

LoaderLib['CodeEditorElement'] = CodeEditorElement;