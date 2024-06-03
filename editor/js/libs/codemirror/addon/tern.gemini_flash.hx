package codemirror.tern;

import codemirror.CodeMirror;
import codemirror.Pos;
import codemirror.Token;
import js.html.Window;
import js.Browser;
import js.Lib;
import js.html.Document;
import js.html.Element;
import js.html.HTMLInputElement;
import js.html.HTMLElement;
import js.html.Node;
import js.html.SpanElement;
import js.html.BodyElement;
import js.html.AnchorElement;
import js.html.ClientRect;
import js.html.Event;
import js.html.MouseEvent;
import js.html.Worker;
import js.html.WorkerGlobalScope;
import js.Browser;
import tern.Server;

class CodeMirrorTernServer {
  public var options:Dynamic;
  public var docs:Dynamic;
  public var server:Dynamic;
  public var trackChange:Dynamic;
  public var cachedArgHints:Dynamic;
  public var activeArgHints:Dynamic;
  public var jumpStack:Array<Dynamic>;
  public var getHint:Dynamic;

  public function new(options:Dynamic = null) {
    this.options = options == null ? {} : options;
    var plugins = this.options.plugins == null ? {} : this.options.plugins;
    if (!plugins.doc_comment) plugins.doc_comment = true;
    this.docs = Lib.objectCreate(null);
    if (this.options.useWorker) {
      this.server = new WorkerServer(this);
    } else {
      this.server = new tern.Server({
        getFile: (name:String, c:Dynamic) -> getFile(this, name, c),
        async: true,
        defs: this.options.defs == null ? [] : this.options.defs,
        plugins: plugins
      });
    }
    this.trackChange = (doc:Dynamic, change:Dynamic) -> trackChange(this, doc, change);

    this.cachedArgHints = null;
    this.activeArgHints = null;
    this.jumpStack = new Array<Dynamic>();

    this.getHint = (cm:CodeMirror, c:Dynamic) -> hint(this, cm, c);
    this.getHint.async = true;
  }

  public function addDoc(name:String, doc:CodeMirror.Doc):Dynamic {
    var data = {doc: doc, name: name, changed: null};
    this.server.addFile(name, docValue(this, data));
    CodeMirror.on(doc, "change", this.trackChange);
    return this.docs[name] = data;
  }

  public function delDoc(id:Dynamic):Void {
    var found = resolveDoc(this, id);
    if (found == null) return;
    CodeMirror.off(found.doc, "change", this.trackChange);
    delete this.docs[found.name];
    this.server.delFile(found.name);
  }

  public function hideDoc(id:Dynamic):Void {
    closeArgHints(this);
    var found = resolveDoc(this, id);
    if (found != null && found.changed != null) sendDoc(this, found);
  }

  public function complete(cm:CodeMirror):Void {
    cm.showHint({hint: this.getHint});
  }

  public function showType(cm:CodeMirror, pos:Pos, c:Dynamic):Void {
    showContextInfo(this, cm, pos, "type", c);
  }

  public function showDocs(cm:CodeMirror, pos:Pos, c:Dynamic):Void {
    showContextInfo(this, cm, pos, "documentation", c);
  }

  public function updateArgHints(cm:CodeMirror):Void {
    updateArgHints(this, cm);
  }

  public function jumpToDef(cm:CodeMirror):Void {
    jumpToDef(this, cm);
  }

  public function jumpBack(cm:CodeMirror):Void {
    jumpBack(this, cm);
  }

  public function rename(cm:CodeMirror):Void {
    rename(this, cm);
  }

  public function selectName(cm:CodeMirror):Void {
    selectName(this, cm);
  }

  public function request(cm:CodeMirror, query:Dynamic, c:Dynamic, pos:Pos = null):Void {
    var self = this;
    var doc = findDoc(this, cm.getDoc());
    var request = buildRequest(this, doc, query, pos);
    var extraOptions = request.query != null && this.options.queryOptions != null ? this.options.queryOptions[request.query.type] : null;
    if (extraOptions != null) {
      for (var prop in extraOptions) {
        request.query[prop] = extraOptions[prop];
      }
    }

    this.server.request(request, (error:Dynamic, data:Dynamic) -> {
      if (error == null && self.options.responseFilter != null) {
        data = self.options.responseFilter(doc, query, request, error, data);
      }
      c(error, data);
    });
  }

  public function destroy():Void {
    closeArgHints(this);
    if (this.worker != null) {
      this.worker.terminate();
      this.worker = null;
    }
  }
}

var cls = "CodeMirror-Tern-";
var bigDoc = 250;

function getFile(ts:CodeMirrorTernServer, name:String, c:Dynamic):Void {
  var buf = ts.docs[name];
  if (buf != null) {
    c(docValue(ts, buf));
  } else if (ts.options.getFile != null) {
    ts.options.getFile(name, c);
  } else {
    c(null);
  }
}

function findDoc(ts:CodeMirrorTernServer, doc:CodeMirror.Doc, name:String = null):Dynamic {
  for (var n in ts.docs) {
    var cur = ts.docs[n];
    if (cur.doc == doc) return cur;
  }
  if (name == null) {
    for (var i = 0;; ++i) {
      n = "[doc" + (i == 0 ? "" : i) + "]";
      if (ts.docs[n] == null) {
        name = n;
        break;
      }
    }
  }
  return ts.addDoc(name, doc);
}

function resolveDoc(ts:CodeMirrorTernServer, id:Dynamic):Dynamic {
  if (typeof id == "string") return ts.docs[id];
  if (Lib.isOfType(id, CodeMirror)) id = id.getDoc();
  if (Lib.isOfType(id, CodeMirror.Doc)) return findDoc(ts, id);
}

function trackChange(ts:CodeMirrorTernServer, doc:CodeMirror.Doc, change:CodeMirror.Change):Void {
  var data = findDoc(ts, doc);

  var argHints = ts.cachedArgHints;
  if (argHints != null && argHints.doc == doc && cmpPos(argHints.start, change.to) >= 0) {
    ts.cachedArgHints = null;
  }

  var changed = data.changed;
  if (changed == null) {
    data.changed = changed = {from: change.from.line, to: change.from.line};
  }
  var end = change.from.line + (change.text.length - 1);
  if (change.from.line < changed.to) {
    changed.to = changed.to - (change.to.line - end);
  }
  if (end >= changed.to) {
    changed.to = end + 1;
  }
  if (changed.from > change.from.line) {
    changed.from = change.from.line;
  }

  if (doc.lineCount() > bigDoc && change.to - changed.from > 100) {
    Browser.window.setTimeout(() -> {
      if (data.changed != null && data.changed.to - data.changed.from > 100) {
        sendDoc(ts, data);
      }
    }, 200);
  }
}

function sendDoc(ts:CodeMirrorTernServer, doc:Dynamic):Void {
  ts.server.request({files: [{type: "full", name: doc.name, text: docValue(ts, doc)}]}, (error:Dynamic) -> {
    if (error != null) {
      Browser.window.console.error(error);
    } else {
      doc.changed = null;
    }
  });
}

// Completion

function hint(ts:CodeMirrorTernServer, cm:CodeMirror, c:Dynamic):Void {
  ts.request(cm, {type: "completions", types: true, docs: true, urls: true}, (error:Dynamic, data:Dynamic) -> {
    if (error != null) return showError(ts, cm, error);
    var completions = new Array<Dynamic>();
    var after = "";
    var from = data.start;
    var to = data.end;
    if (cm.getRange(Pos(from.line, from.ch - 2), from) == "[\"" && cm.getRange(to, Pos(to.line, to.ch + 2)) != "\"]") {
      after = "\"]";
    }

    for (var i = 0; i < data.completions.length; ++i) {
      var completion = data.completions[i];
      var className = typeToIcon(completion.type);
      if (data.guess) {
        className += " " + cls + "guess";
      }
      completions.push({text: completion.name + after,
                        displayText: completion.displayName == null ? completion.name : completion.displayName,
                        className: className,
                        data: completion});
    }

    var obj = {from: from, to: to, list: completions};
    var tooltip = null;
    CodeMirror.on(obj, "close", () -> remove(tooltip));
    CodeMirror.on(obj, "update", () -> remove(tooltip));
    CodeMirror.on(obj, "select", (cur:Dynamic, node:Dynamic) -> {
      remove(tooltip);
      var content = ts.options.completionTip != null ? ts.options.completionTip(cur.data) : cur.data.doc;
      if (content != null) {
        tooltip = makeTooltip(node.parentNode.getBoundingClientRect().right + Browser.window.pageXOffset,
                              node.getBoundingClientRect().top + Browser.window.pageYOffset, content, cm, cls + "hint-doc");
      }
    });
    c(obj);
  });
}

function typeToIcon(type:String):String {
  var suffix:String;
  if (type == "?") suffix = "unknown";
  else if (type == "number" || type == "string" || type == "bool") suffix = type;
  else if (Lib.startsWith(type, "fn(")) suffix = "fn";
  else if (Lib.startsWith(type, "[")) suffix = "array";
  else suffix = "object";
  return cls + "completion " + cls + "completion-" + suffix;
}

// Type queries

function showContextInfo(ts:CodeMirrorTernServer, cm:CodeMirror, pos:Pos, queryName:String, c:Dynamic):Void {
  ts.request(cm, queryName, (error:Dynamic, data:Dynamic) -> {
    if (error != null) return showError(ts, cm, error);
    var tip:Dynamic;
    if (ts.options.typeTip != null) {
      tip = ts.options.typeTip(data);
    } else {
      tip = elt("span", null, elt("strong", null, data.type == null ? "not found" : data.type));
      if (data.doc != null) {
        tip.appendChild(Document.createTextNode(" — " + data.doc));
      }
      if (data.url != null) {
        tip.appendChild(Document.createTextNode(" "));
        var child = tip.appendChild(elt("a", null, "[docs]"));
        child.href = data.url;
        child.target = "_blank";
      }
    }
    tempTooltip(cm, tip, ts);
    if (c != null) c();
  }, pos);
}

// Maintaining argument hints

function updateArgHints(ts:CodeMirrorTernServer, cm:CodeMirror):Void {
  closeArgHints(ts);

  if (cm.somethingSelected()) return;
  var state = cm.getTokenAt(cm.getCursor()).state;
  var inner = CodeMirror.innerMode(cm.getMode(), state);
  if (inner.mode.name != "javascript") return;
  var lex = inner.state.lexical;
  if (lex.info != "call") return;

  var ch:Int, argPos:Int = lex.pos == null ? 0 : lex.pos, tabSize:Int = cm.getOption("tabSize");
  for (var line = cm.getCursor().line, e = Math.max(0, line - 9), found = false; line >= e; --line) {
    var str = cm.getLine(line);
    var extra = 0;
    for (var pos = 0;;) {
      var tab = str.indexOf("\t", pos);
      if (tab == -1) break;
      extra += tabSize - (tab + extra) % tabSize - 1;
      pos = tab + 1;
    }
    ch = lex.column - extra;
    if (str.charAt(ch) == "(") {
      found = true;
      break;
    }
  }
  if (!found) return;

  var start = Pos(line, ch);
  var cache = ts.cachedArgHints;
  if (cache != null && cache.doc == cm.getDoc() && cmpPos(start, cache.start) == 0) {
    return showArgHints(ts, cm, argPos);
  }

  ts.request(cm, {type: "type", preferFunction: true, end: start}, (error:Dynamic, data:Dynamic) -> {
    if (error != null || data.type == null || !Lib.startsWith(data.type, "fn(")) return;
    ts.cachedArgHints = {
      start: start,
      type: parseFnType(data.type),
      name: data.exprName == null ? data.name == null ? "fn" : data.name : data.exprName,
      guess: data.guess,
      doc: cm.getDoc()
    };
    showArgHints(ts, cm, argPos);
  });
}

function showArgHints(ts:CodeMirrorTernServer, cm:CodeMirror, pos:Int):Void {
  closeArgHints(ts);

  var cache = ts.cachedArgHints;
  var tp = cache.type;
  var tip = elt("span", cache.guess ? cls + "fhint-guess" : null,
                elt("span", cls + "fname", cache.name), "(");
  for (var i = 0; i < tp.args.length; ++i) {
    if (i != 0) tip.appendChild(Document.createTextNode(", "));
    var arg = tp.args[i];
    tip.appendChild(elt("span", cls + "farg" + (i == pos ? " " + cls + "farg-current" : ""), arg.name == null ? "?" : arg.name));
    if (arg.type != "?") {
      tip.appendChild(Document.createTextNode(":\u00a0"));
      tip.appendChild(elt("span", cls + "type", arg.type));
    }
  }
  tip.appendChild(Document.createTextNode(tp.rettype != null ? ") ->\u00a0" : ")"));
  if (tp.rettype != null) tip.appendChild(elt("span", cls + "type", tp.rettype));
  var place = cm.cursorCoords(null, "page");
  var tooltip = ts.activeArgHints = makeTooltip(place.right + 1, place.bottom, tip, cm);
  Browser.window.setTimeout(() -> {
    tooltip.clear = onEditorActivity(cm, () -> {
      if (ts.activeArgHints == tooltip) closeArgHints(ts);
    });
  }, 20);
}

function parseFnType(text:String):Dynamic {
  var args = new Array<Dynamic>();
  var pos = 3;

  function skipMatching(upto:RegExp):String {
    var depth = 0;
    var start = pos;
    for (;;) {
      var next = text.charAt(pos);
      if (upto.test(next) && !depth) return text.slice(start, pos);
      if (Lib.match(next, /[{\[\(]/)) ++depth;
      else if (Lib.match(next, /[\}\]\)]/)) --depth;
      ++pos;
    }
  }

  // Parse arguments
  if (text.charAt(pos) != ")") {
    for (;;) {
      var name = text.slice(pos).match(/^([^, \(\[\{]+): /);
      if (name != null) {
        pos += name[0].length;
        name = name[1];
      }
      args.push({name: name, type: skipMatching(/[\),]/)});
      if (text.charAt(pos) == ")") break;
      pos += 2;
    }
  }

  var rettype = text.slice(pos).match(/^\) -> (.*)$/);

  return {args: args, rettype: rettype != null ? rettype[1] : null};
}

// Moving to the definition of something

function jumpToDef(ts:CodeMirrorTernServer, cm:CodeMirror):Void {
  function inner(varName:String = null):Void {
    var req = {type: "definition", variable: varName == null ? null : varName};
    var doc = findDoc(ts, cm.getDoc());
    ts.server.request(buildRequest(ts, doc, req), (error:Dynamic, data:Dynamic) -> {
      if (error != null) return showError(ts, cm, error);
      if (data.file == null && data.url != null) {
        Browser.window.open(data.url);
        return;
      }

      if (data.file != null) {
        var localDoc = ts.docs[data.file];
        var found:Dynamic;
        if (localDoc != null && (found = findContext(localDoc.doc, data)) != null) {
          ts.jumpStack.push({file: doc.name,
                            start: cm.getCursor("from"),
                            end: cm.getCursor("to")});
          moveTo(ts, doc, localDoc, found.start, found.end);
          return;
        }
      }
      showError(ts, cm, "Could not find a definition.");
    });
  }

  if (!atInterestingExpression(cm)) {
    dialog(cm, "Jump to variable", (name:String) -> {
      if (name != null) inner(name);
    });
  } else {
    inner();
  }
}

function jumpBack(ts:CodeMirrorTernServer, cm:CodeMirror):Void {
  var pos = ts.jumpStack.pop();
  var doc = pos != null ? ts.docs[pos.file] : null;
  if (doc == null) return;
  moveTo(ts, findDoc(ts, cm.getDoc()), doc, pos.start, pos.end);
}

function moveTo(ts:CodeMirrorTernServer, curDoc:Dynamic, doc:Dynamic, start:Pos, end:Pos):Void {
  doc.doc.setSelection(start, end);
  if (curDoc != doc && ts.options.switchToDoc != null) {
    closeArgHints(ts);
    ts.options.switchToDoc(doc.name, doc.doc);
  }
}

// The {line,ch} representation of positions makes this rather awkward.
function findContext(doc:CodeMirror.Doc, data:Dynamic):Dynamic {
  var before = data.context.slice(0, data.contextOffset).split("\n");
  var startLine = data.start.line - (before.length - 1);
  var start = Pos(startLine, (before.length == 1 ? data.start.ch : doc.getLine(startLine).length) - before[0].length);

  var text = doc.getLine(startLine).slice(start.ch);
  for (var cur = startLine + 1; cur < doc.lineCount() && text.length < data.context.length; ++cur) {
    text += "\n" + doc.getLine(cur);
  }
  if (Lib.startsWith(text, data.context)) return data;

  var cursor = doc.getSearchCursor(data.context, 0, false);
  var nearest:Dynamic, nearestDist = Infinity;
  while (cursor.findNext()) {
    var from = cursor.from();
    var dist = Math.abs(from.line - start.line) * 10000;
    if (dist == 0) dist = Math.abs(from.ch - start.ch);
    if (dist < nearestDist) {
      nearest = from;
      nearestDist = dist;
    }
  }
  if (nearest == null) return null;

  if (before.length == 1) {
    nearest.ch += before[0].length;
  } else {
    nearest = Pos(nearest.line + (before.length - 1), before[before.length - 1].length);
  }
  if (data.start.line == data.end.line) {
    var end = Pos(nearest.line, nearest.ch + (data.end.ch - data.start.ch));
  } else {
    var end = Pos(nearest.line + (data.end.line - data.start.line), data.end.ch);
  }
  return {start: nearest, end: end};
}

function atInterestingExpression(cm:CodeMirror):Bool {
  var pos = cm.getCursor("end");
  var tok = cm.getTokenAt(pos);
  if (tok.start < pos.ch && tok.type == "comment") return false;
  return Lib.match(cm.getLine(pos.line).slice(Math.max(pos.ch - 1, 0), pos.ch + 1), /[\w)\]]/);
}

// Variable renaming

function rename(ts:CodeMirrorTernServer, cm:CodeMirror):Void {
  var token = cm.getTokenAt(cm.getCursor());
  if (!Lib.match(token.string, /\w/)) return showError(ts, cm, "Not at a variable");
  dialog(cm, "New name for " + token.string, (newName:String) -> {
    ts.request(cm, {type: "rename", newName: newName, fullDocs: true}, (error:Dynamic, data:Dynamic) -> {
      if (error != null) return showError(ts, cm, error);
      applyChanges(ts, data.changes);
    });
  });
}

function selectName(ts:CodeMirrorTernServer, cm:CodeMirror):Void {
  var name = findDoc(ts, cm.doc).name;
  ts.request(cm, {type: "refs"}, (error:Dynamic, data:Dynamic) -> {
    if (error != null) return showError(ts, cm, error);
    var ranges = new Array<Dynamic>();
    var cur = 0;
    var curPos = cm.getCursor();
    for (var i = 0; i < data.refs.length; i++) {
      var ref = data.refs[i];
      if (ref.file == name) {
        ranges.push({anchor: ref.start, head: ref.end});
        if (cmpPos(curPos, ref.start) >= 0 && cmpPos(curPos, ref.end) <= 0) {
          cur = ranges.length - 1;
        }
      }
    }
    cm.setSelections(ranges, cur);
  });
}

var nextChangeOrig = 0;
function applyChanges(ts:CodeMirrorTernServer, changes:Array<Dynamic>):Void {
  var perFile = Lib.objectCreate(null);
  for (var i = 0; i < changes.length; ++i) {
    var ch = changes[i];
    (perFile[ch.file] == null ? perFile[ch.file] = new Array<Dynamic>() : perFile[ch.file]).push(ch);
  }
  for (var file in perFile) {
    var known = ts.docs[file];
    var chs = perFile[file];
    if (known == null) continue;
    chs.sort((a:Dynamic, b:Dynamic) -> cmpPos(b.start, a.start));
    var origin = "*rename" + (++nextChangeOrig);
    for (var i = 0; i < chs.length; ++i) {
      var ch = chs[i];
      known.doc.replaceRange(ch.text, ch.start, ch.end, origin);
    }
  }
}

// Generic request-building helper

function buildRequest(ts:CodeMirrorTernServer, doc:Dynamic, query:Dynamic, pos:Pos = null):Dynamic {
  var files = new Array<Dynamic>();
  var offsetLines = 0;
  var allowFragments = query.fullDocs == null ? true : !query.fullDocs;
  if (!allowFragments) delete query.fullDocs;
  if (typeof query == "string") query = {type: query};
  query.lineCharPositions = true;
  if (query.end == null) {
    query.end = pos == null ? doc.doc.getCursor("end") : pos;
    if (doc.doc.somethingSelected()) {
      query.start = doc.doc.getCursor("start");
    }
  }
  var startPos = query.start == null ? query.end : query.start;

  if (doc.changed != null) {
    if (doc.doc.lineCount() > bigDoc && allowFragments !== false &&
        doc.changed.to - doc.changed.from < 100 &&
        doc.changed.from <= startPos.line && doc.changed.to > query.end.line) {
      files.push(getFragmentAround(doc, startPos, query.end));
      query.file = "#0";
      var offsetLines = files[0].offsetLines;
      if (query.start != null) query.start = Pos(query.start.line - -offsetLines, query.start.ch);
      query.end = Pos(query.end.line - offsetLines, query.end.ch);
    } else {
      files.push({type: "full",
                  name: doc.name,
                  text: docValue(ts, doc)});
      query.file = doc.name;
      doc.changed = null;
    }
  } else {
    query.file = doc.name;
  }
  for (var name in ts.docs) {
    var cur = ts.docs[name];
    if (cur.changed != null && cur != doc) {
      files.push({type: "full", name: cur.name, text: docValue(ts, cur)});
      cur.changed = null;
    }
  }

  return {query: query, files: files};
}

function getFragmentAround(data:Dynamic, start:Pos, end:Pos):Dynamic {
  var doc = data.doc;
  var minIndent:Int = null;
  var minLine:Int = null;
  var endLine:Int;
  var tabSize = 4;
  for (var p = start.line - 1, min = Math.max(0, p - 50); p >= min; --p) {
    var line = doc.getLine(p);
    var fn = line.search(/\bfunction\b/);
    if (fn < 0) continue;
    var indent = CodeMirror.countColumn(line, null, tabSize);
    if (minIndent != null && minIndent <= indent) continue;
    minIndent = indent;
    minLine = p;
  }
  if (minLine == null) minLine = min;
  var max = Math.min(doc.lastLine(), end.line + 20);
  if (minIndent == null || minIndent == CodeMirror.countColumn(doc.getLine(start.line), null, tabSize)) {
    endLine = max;
  } else {
    for (endLine = end.line + 1; endLine < max; ++endLine) {
      var indent = CodeMirror.countColumn(doc.getLine(endLine), null, tabSize);
      if (indent <= minIndent) break;
    }
  }
  var from = Pos(minLine, 0);

  return {type: "part",
          name: data.name,
          offsetLines: from.line,
          text: doc.getRange(from, Pos(endLine, end.line == endLine ? null : 0))};
}

// Generic utilities

var cmpPos = CodeMirror.cmpPos;

function elt(tagname:String, cls:String = null, ?elts:Array<Dynamic>):HTMLElement {
  var e = Document.createElement(tagname);
  if (cls != null) e.className = cls;
  for (var i = 2; i < arguments.length; ++i) {
    var elt = arguments[i];
    if (typeof elt == "string") elt = Document.createTextNode(elt);
    e.appendChild(elt);
  }
  return e;
}

function dialog(cm:CodeMirror, text:String, f:Dynamic):Void {
  if (cm.openDialog != null) {
    cm.openDialog(text + ": <input type=text>", f);
  } else {
    f(Browser.window.prompt(text, ""));
  }
}

// Tooltips

function tempTooltip(cm:CodeMirror, content:Dynamic, ts:CodeMirrorTernServer):Void {
  if (cm.state.ternTooltip != null) remove(cm.state.ternTooltip);
  var where = cm.cursorCoords();
  var tip = cm.state.ternTooltip = makeTooltip(where.right + 1, where.bottom, content, cm);
  function maybeClear():Void {
    old = true;
    if (!mouseOnTip) clear();
  }
  function clear():Void {
    cm.state.ternTooltip = null;
    if (tip.parentNode != null) fadeOut(tip);
    clearActivity();
  }
  var mouseOnTip = false;
  var old = false;
  CodeMirror.on(tip, "mousemove", () -> {
    mouseOnTip = true;
  });
  CodeMirror.on(tip, "mouseout", (e:MouseEvent) -> {
    var related = e.relatedTarget == null ? e.toElement : e.relatedTarget;
    if (related == null || !CodeMirror.contains(tip, related)) {
      if (old) clear();
      else mouseOnTip = false;
    }
  });
  Browser.window.setTimeout(maybeClear, ts.options.hintDelay != null ? ts.options.hintDelay : 1700);
  var clearActivity = onEditorActivity(cm, clear);
}

function onEditorActivity(cm:CodeMirror, f:Dynamic):Dynamic {
  cm.on("cursorActivity", f);
  cm.on("blur", f);
  cm.on("scroll", f);
  cm.on("setDoc", f);
  return () -> {
    cm.off("cursorActivity", f);
    cm.off("blur", f);
    cm.off("scroll", f);
    cm.off("setDoc", f);
  };
}

function makeTooltip(x:Int, y:Int, content:Dynamic, cm:CodeMirror, className:String = null):HTMLElement {
  var node = elt("div", cls + "tooltip" + " " + (className == null ? "" : className), content);
  node.style.left = x + "px";
  node.style.top = y + "px";
  var container = ((cm.options == null ? {} : cm.options).hintOptions == null ? {} : cm.options.hintOptions).container == null ? Browser.document.body : ((cm.options == null ? {} : cm.options).hintOptions == null ? {} : cm.options.hintOptions).container;
  container.appendChild(node);

  var pos = cm.cursorCoords();
  var winW = Browser.window.innerWidth;
  var winH = Browser.window.innerHeight;
  var box = node.getBoundingClientRect();
  var hints = Browser.document.querySelector(".CodeMirror-hints");
  var overlapY = box.bottom - winH;
  var overlapX = box.right - winW;

  if (hints != null && overlapX > 0) {
    node.style.left = "0";
    var box = node.getBoundingClientRect();
    node.style.left = (x = x - hints.offsetWidth - box.width) + "px";
    overlapX = box.right - winW;
  }
  if (overlapY > 0) {
    var height = box.bottom - box.top;
    var curTop = pos.top - (pos.bottom - box.top);
    if (curTop - height > 0) { // Fits above cursor
      node.style.top = (pos.top - height) + "px";
    } else if (height > winH) {
      node.style.height = (winH - 5) + "px";
      node.style.top = (pos.bottom - box.top) + "px";
    }
  }
  if (overlapX > 0) {
    if (box.right - box.left > winW) {
      node.style.width = (winW - 5) + "px";
      overlapX -= (box.right - box.left) - winW;
    }
    node
    node.style.left = (x - overlapX) + "px";
  }

  return node;
}

function remove(node:Node):Void {
  var p = node != null ? node.parentNode : null;
  if (p != null) p.removeChild(node);
}

function fadeOut(tooltip:HTMLElement):Void {
  tooltip.style.opacity = "0";
  Browser.window.setTimeout(() -> {
    remove(tooltip);
  }, 1100);
}

function showError(ts:CodeMirrorTernServer, cm:CodeMirror, msg:Dynamic):Void {
  if (ts.options.showError != null) {
    ts.options.showError(cm, msg);
  } else {
    tempTooltip(cm, String(msg), ts);
  }
}

function closeArgHints(ts:CodeMirrorTernServer):Void {
  if (ts.activeArgHints != null) {
    if (ts.activeArgHints.clear != null) ts.activeArgHints.clear();
    remove(ts.activeArgHints);
    ts.activeArgHints = null;
  }
}

function docValue(ts:CodeMirrorTernServer, doc:Dynamic):String {
  var val = doc.doc.getValue();
  if (ts.options.fileFilter != null) val = ts.options.fileFilter(val, doc.name, doc.doc);
  return val;
}

// Worker wrapper

class WorkerServer {
  public var worker:Worker;
  public var ts:CodeMirrorTernServer;

  public function new(ts:CodeMirrorTernServer) {
    this.ts = ts;
    this.worker = new Worker(ts.options.workerScript);
    this.worker.postMessage({type: "init",
                        defs: ts.options.defs,
                        plugins: ts.options.plugins,
                        scripts: ts.options.workerDeps});
    var msgId = 0;
    var pending = {};

    function send(data:Dynamic, c:Dynamic):Void {
      if (c != null) {
        data.id = ++msgId;
        pending[msgId] = c;
      }
      this.worker.postMessage(data);
    }
    this.worker.onmessage = (e:Event) -> {
      var data = e.data;
      if (data.type == "getFile") {
        getFile(ts, data.name, (err:Dynamic, text:String) -> {
          send({type: "getFile", err: String(err), text: text, id: data.id});
        });
      } else if (data.type == "debug") {
        Browser.window.console.log(data.message);
      } else if (data.id != null && pending[data.id] != null) {
        pending[data.id](data.err, data.body);
        delete pending[data.id];
      }
    };
    this.worker.onerror = (e:Event) -> {
      for (var id in pending) {
        pending[id](e);
      }
      pending = {};
    };

    this.addFile = (name:String, text:String) -> send({type: "add", name: name, text: text});
    this.delFile = (name:String) -> send({type: "del", name: name});
    this.request = (body:Dynamic, c:Dynamic) -> send({type: "req", body: body}, c);
  }
}