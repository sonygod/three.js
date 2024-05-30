import flow.Element;
import flow.LoaderLib;
import js.Browser.document;
import js.Browser.window;

class CodeEditorElement extends Element {

    var updateInterval:Int = 500;
    var _source:String;
    var editor:Dynamic;

    public function new( ?source:String = '' ) {

        super();

        this._source = source;

        this.dom.style.setProperty('z-index', '-1');
        this.dom.classList.add('no-zoom');

        this.setHeight(500);

        var editorDOM = document.createElement('div');
        editorDOM.style.width = '100%';
        editorDOM.style.height = '100%';
        this.dom.appendChild(editorDOM);

        this.editor = null; // async

        window.require.config( { paths: { 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.48.0/min/vs' } } );

        require( ['vs/editor/editor.main'], () -> {

            this.editor = window.monaco.editor.create( editorDOM, {
                value: this.source,
                language: 'javascript',
                theme: 'vs-dark',
                automaticLayout: true,
                minimap: { enabled: false }
            });

            var timeout:Dynamic = null;

            this.editor.getModel().onDidChangeContent( () -> {

                this._source = this.editor.getValue();

                if (timeout != null) {
                    js.Browser.window.clearTimeout(timeout);
                }

                timeout = js.Browser.window.setTimeout( () -> {
                    this.dispatchEvent(new Event('change'));
                }, this.updateInterval);

            });

        });

    }

    public function set_source( value:String ):Void {

        if ( this._source == value ) return;

        this._source = value;

        if ( this.editor != null ) this.editor.setValue(value);

        this.dispatchEvent(new Event('change'));

    }

    public function get_source():String {

        return this._source;

    }

    public function focus():Void {

        if ( this.editor != null ) this.editor.focus();

    }

    public override function serialize( data:Dynamic ):Void {

        super.serialize(data);

        data.source = this.source;

    }

    public override function deserialize( data:Dynamic ):Void {

        super.deserialize(data);

        this.source = data.source != null ? data.source : '';

    }

}

LoaderLib.set('CodeEditorElement', CodeEditorElement);