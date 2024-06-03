// CodeMirror, copyright (c) by Marijn Haverbeke and others
// Distributed under an MIT license: https://codemirror.net/LICENSE

// Glue code between CodeMirror and Tern.
//
// Create a TernServer to wrap an actual Tern server,
// register open documents (CodeMirror.Doc instances) with it, and
// call its methods to activate the assisting functions that Tern
// provides.
//
// Options supported (all optional):
// * defs: An array of JSON definition data structures.
// * plugins: An object mapping plugin names to configuration
//   options.
// * getFile: A function(name, c) that can be used to access files in
//   the project that haven't been loaded yet. Simply do c(null) to
//   indicate that a file is not available.
// * fileFilter: A function(value, docName, doc) that will be applied
//   to documents before passing them on to Tern.
// * switchToDoc: A function(name, doc) that should, when providing a
//   multi-file view, switch the view or focus to the named file.
// * showError: A function(editor, message) that can be used to
//   override the way errors are displayed.
// * completionTip: Customize the content in tooltips for completions.
//   Is passed a single argument—the completion's data as returned by
//   Tern—and may return a string, DOM node, or null to indicate that
//   no tip should be shown. By default the docstring is shown.
// * typeTip: Like completionTip, but for the tooltips shown for type
//   queries.
// * responseFilter: A function(doc, query, request, error, data) that
//   will be applied to the Tern responses before treating them
//
//
// It is possible to run the Tern server in a web worker by specifying
// these additional options:
// * useWorker: Set to true to enable web worker mode. You'll probably
//   want to feature detect the actual value you use here, for example
//   !!window.Worker.
// * workerScript: The main script of the worker. Point this to
//   wherever you are hosting worker.js from this directory.
// * workerDeps: An array of paths pointing (relative to workerScript)
//   to the Acorn and Tern libraries and any Tern plugins you want to
//   load. Or, if you minified those into a single script and included
//   them in the workerScript, simply leave this undefined.

class CodeMirror {
    // Some of the CodeMirror methods are used directly, so they need to be defined or imported
    // For example:
    // static function on(target:Dynamic, event:String, handler:Function):Void {}
    // static function off(target:Dynamic, event:String, handler:Function):Void {}
    // static function innerMode(mode:Dynamic, state:Dynamic):Dynamic {}
    // ...
}

class TernServer {
    var options:Dynamic;
    var docs:Dynamic;
    var server:Dynamic;
    var trackChange:Function;
    var cachedArgHints:Dynamic;
    var activeArgHints:Dynamic;
    var jumpStack:Array<Dynamic>;
    var getHint:Function;

    public function new(options:Dynamic = null) {
        this.options = options != null ? options : {};
        var plugins = this.options.plugins != null ? this.options.plugins : (this.options.plugins = {});
        if (plugins.doc_comment == null) plugins.doc_comment = true;
        this.docs = js.Boot.newObject();
        if (this.options.useWorker) {
            this.server = new WorkerServer(this);
        } else {
            // The tern library is not available in Haxe, so this part needs to be implemented or imported
            // this.server = new tern.Server({
            //     getFile: function(name, c) { return getFile(self, name, c); },
            //     async: true,
            //     defs: this.options.defs != null ? this.options.defs : [],
            //     plugins: plugins
            // });
        }
        this.trackChange = function(doc:Dynamic, change:Dynamic) { trackChange(this, doc, change); };

        this.cachedArgHints = null;
        this.activeArgHints = null;
        this.jumpStack = [];

        this.getHint = function(cm:Dynamic, c:Function):Void { hint(this, cm, c); };
        this.getHint.async = true;
    }

    public function addDoc(name:String, doc:Dynamic):Dynamic {
        var data = {doc: doc, name: name, changed: null};
        this.server.addFile(name, docValue(this, data));
        CodeMirror.on(doc, "change", this.trackChange);
        this.docs[name] = data;
        return data;
    }

    // ... other methods ...
}

// ... other functions ...

class WorkerServer {
    var worker:Worker;

    public function new(ts:TernServer) {
        // The Worker class is not available in Haxe, so this part needs to be implemented or imported
        // var worker = ts.worker = new Worker(ts.options.workerScript);
        // worker.postMessage({type: "init",
        //                     defs: ts.options.defs,
        //                     plugins: ts.options.plugins,
        //                     scripts: ts.options.workerDeps});
        // ...
    }

    // ... other methods ...
}