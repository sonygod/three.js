package tern;

import codemirror.CodeMirror;
import js.Browser;
import js.html.Document;
import js.html.Element;

class TernServer {
  public var options:Dynamic;
  public var docs:Dynamic;
  public var server:TernServer;
  public var cachedArgHints:Dynamic;
  public var activeArgHints:Dynamic;
  public var jumpStack:Array<Dynamic>;

  public function new(options:Dynamic) {
    this.options = options;
    this.docs = {};
    this.cachedArgHints = null;
    this.activeArgHints = null;
    this.jumpStack = [];

    if (options.useWorker) {
      this.server = new WorkerServer(this);
    } else {
      this.server = new TernServerInstance({
        getFile: function(name:String, c:Dynamic->Void) {
          getFile(this, name, c);
        },
        async: true,
        defs: options.defs,
        plugins: options.plugins
      });
    }
  }

  public function addDoc(name:String, doc:CodeMirror.Doc):Dynamic {
    var data:Dynamic = {doc: doc, name: name, changed: null};
    this.server.addFile(name, docValue(this, data));
    CodeMirror.on(doc, "change", trackChange(this, doc));
    return this.docs[name] = data;
  }

  public function delDoc(id:Dynamic):Void {
    var found:Dynamic = resolveDoc(this, id);
    if (found == null) return;
    CodeMirror.off(found.doc, "change", trackChange(this, found.doc));
    delete this.docs[found.name];
    this.server.delFile(found.name);
  }

  public function hideDoc(id:Dynamic):Void {
    closeArgHints(this);
    var found:Dynamic = resolveDoc(this, id);
    if (found != null) sendDoc(this, found);
  }

  public function complete(cm:CodeMirror.Editor):Void {
    cm.showHint({hint: getHint(this, cm)});
  }

  public function showType(cm:CodeMirror.Editor, pos:Dynamic, c:Dynamic->Void):Void {
    showContextInfo(this, cm, pos, "type", c);
  }

  public function showDocs(cm:CodeMirror.Editor, pos:Dynamic, c:Dynamic->Void):Void {
    showContextInfo(this, cm, pos, "documentation", c);
  }

  public function updateArgHints(cm:CodeMirror.Editor):Void {
    updateArgHints(this, cm);
  }

  public function jumpToDef(cm:CodeMirror.Editor):Void {
    jumpToDef(this, cm);
  }

  public function jumpBack(cm:CodeMirror.Editor):Void {
    jumpBack(this, cm);
  }

  public function rename(cm:CodeMirror.Editor):Void {
    rename(this, cm);
  }

  public function selectName(cm:CodeMirror.Editor):Void {
    selectName(this, cm);
  }

  public function request(cm:CodeMirror.Editor, query:Dynamic, c:Dynamic->Void, pos:Dynamic):Void {
    request(this, cm, query, c, pos);
  }

  public function destroy():Void {
    closeArgHints(this);
    if (this.worker != null) {
      this.worker.terminate();
      this.worker = null;
    }
  }
}

class WorkerServer {
  public var worker:Worker;

  public function new(ts:TernServer) {
    this.worker = Browser.window.createWorker('worker.js');
    worker.postMessage({type: "init", defs: ts.options.defs, plugins: ts.options.plugins, scripts: ts.options.workerDeps});
    var msgId:Int = 0;
    var pending:Dynamic = {};

    function send(data:Dynamic, c:Dynamic->Void):Void {
      if (c != null) {
        data.id = ++msgId;
        pending[msgId] = c;
      }
      worker.postMessage(data);
    }

    worker.onmessage = function(e:Dynamic):Void {
      var data:Dynamic = e.data;
      if (data.type == "getFile") {
        getFile(ts, data.name, function(err:Dynamic, text:String):Void {
          send({type: "getFile", err: err, text: text, id: data.id});
        });
      } else if (data.type == "debug") {
        trace(data.message);
      } else if (data.id != null && pending[data.id] != null) {
        pending[data.id](data.err, data.body);
        Reflect.deleteField(pending, data.id);
      }
    };

    worker.onerror = function(e:Dynamic):Void {
      for (id in pending) pending[id](e);
      pending = {};
    };

    this.addFile = function(name:String, text:String):Void {
      send({type: "add", name: name, text: text});
    };

    this.delFile = function(name:String):Void {
      send({type: "del", name: name});
    };

    this.request = function(body:Dynamic, c:Dynamic->Void):Void {
      send({type: "req", body: body}, c);
    };
  }
}

// ...