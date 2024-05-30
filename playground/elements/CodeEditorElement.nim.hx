import Element;
import LoaderLib;

class CodeEditorElement extends Element {

	var updateInterval:Int = 500;
	var _source:String;

	public function new(source:String = '') {

		super();

		this._source = source;

		this.dom.style.zIndex = -1;
		this.dom.classList.add('no-zoom');

		this.setHeight(500);

		var editorDOM = js.Browser.document.createElement('div');
		editorDOM.style.width = '100%';
		editorDOM.style.height = '100%';
		this.dom.appendChild(editorDOM);

		this.editor = null; // async

		js.Browser.window.require.config({ paths: { 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.48.0/min/vs' } });

		js.Browser.window.require(['vs/editor/editor.main'], function(editor) {

			this.editor = js.Browser.window.monaco.editor.create(editorDOM, {
				value: this.source,
				language: 'javascript',
				theme: 'vs-dark',
				automaticLayout: true,
				minimap: { enabled: false }
			});

			var timeout:Dynamic;

			this.editor.getModel().onDidChangeContent(function() {

				this._source = this.editor.getValue();

				if (timeout != null) js.Browser.clearTimeout(timeout);

				timeout = js.Browser.setTimeout(function() {

					this.dispatchEvent(new Event('change'));

				}, this.updateInterval);

			});

		});

	}

	public function set source(value:String) {

		if (this._source == value) return;

		this._source = value;

		if (this.editor != null) this.editor.setValue(value);

		this.dispatchEvent(new Event('change'));

	}

	public function get source():String {

		return this._source;

	}

	public function focus() {

		if (this.editor != null) this.editor.focus();

	}

	public function serialize(data:Dynamic) {

		super.serialize(data);

		data.source = this.source;

	}

	public function deserialize(data:Dynamic) {

		super.deserialize(data);

		this.source = data.source || '';

	}

}

LoaderLib['CodeEditorElement'] = CodeEditorElement;