package tern;

import tern.infer.Context;
import tern.infer.Obj;
import tern.infer.Type;
import tern.infer.def;
import tern.infer.Infer;
import tern.signal.Signal;
import acorn.walk;
import acorn.Parser;
import acorn.Options;

class File {
  public var name:String;
  public var parent:String;
  public var scope:infer.Scope;
  public var text:String;
  public var ast:acorn.Node;
  public var lineOffsets:Array<Int>;

  public function new(name:String, parent:String) {
    this.name = name;
    this.parent = parent;
    this.scope = null;
    this.text = null;
    this.ast = null;
    this.lineOffsets = null;
  }

  public function asLineChar(pos:Int):{line:Int, ch:Int} {
    return asLineChar(this, pos);
  }
}

class Server extends Signal {
  public var cx:Context;
  public var options:ServerOptions;
  public var handlers:Dynamic;
  public var files:Array<File>;
  public var fileMap:Dynamic;
  public var needsPurge:Array<String>;
  public var budgets:Dynamic;
  public var uses:Int;
  public var pending:Int;
  public var asyncError:Dynamic;
  public var passes:Dynamic;
  public var defs:Array<Dynamic>;

  public function new(options:ServerOptions) {
    super();
    this.cx = null;
    this.options = options;
    if (options == null) this.options = new ServerOptions();
    for (o in defaultOptions) if (!this.options.hasOwnProperty(o)) {
      this.options[o] = defaultOptions[o];
    }
    this.handlers = {};
    this.files = [];
    this.fileMap = {};
    this.needsPurge = [];
    this.budgets = {};
    this.uses = 0;
    this.pending = 0;
    this.asyncError = null;
    this.passes = {};
    this.defs = this.options.defs.copy();
    for (plugin in this.options.plugins) {
      if (this.options.plugins.hasOwnProperty(plugin) && plugin in plugins) {
        var init = plugins[plugin](this, this.options.plugins[plugin]);
        if (init != null && init.defs != null) {
          if (init.loadFirst) this.defs.unshift(init.defs);
          else this.defs.push(init.defs);
        }
        if (init != null && init.passes != null) {
          for (type in init.passes) {
            if (init.passes.hasOwnProperty(type)) {
              var typePasses = this.passes[type];
              if (typePasses == null) {
                this.passes[type] = [init.passes[type]];
              } else {
                typePasses.push(init.passes[type]);
              }
            }
          }
        }
      }
    }
    this.reset();
  }

  public function addFile(name:String, text:String = null, parent:String = null):Void {
    if (parent != null && !(parent in this.fileMap)) parent = null;
    ensureFile(this, name, parent, text);
  }

  public function delFile(name:String):Void {
    var file = this.findFile(name);
    if (file != null) {
      this.needsPurge.push(file.name);
      this.files.splice(this.files.indexOf(file), 1);
      delete this.fileMap[name];
    }
  }

  public function reset():Void {
    this.signal("reset");
    this.cx = new Context(this.defs, this);
    this.uses = 0;
    this.budgets = {};
    for (i in 0...this.files.length) {
      var file = this.files[i];
      file.scope = null;
    }
  }

  public function request(doc:Request, c:Dynamic->Void):Void {
    var inv = invalidDoc(doc);
    if (inv != null) return c(inv);
    var self = this;
    doRequest(this, doc, function(err:Dynamic, data:Dynamic) {
      c(err, data);
      if (self.uses > 40) {
        self.reset();
        analyzeAll(self, null, function() {});
      }
    });
  }

  public function findFile(name:String):File {
    return this.fileMap[name];
  }

  public function flush(c:Dynamic->Void):Void {
    var cx = this.cx;
    analyzeAll(this, null, function(err:Dynamic) {
      if (err != null) return c(err);
      Infer.withContext(cx, c);
    });
  }

  public function startAsyncAction():Void {
    ++this.pending;
  }

  public function finishAsyncAction(err:Dynamic):Void {
    if (err != null) this.asyncError = err;
    if (--this.pending == 0) this.signal("everythingFetched");
  }
}

class ServerOptions {
  public var debug:Bool;
  public var async:Bool;
  public var getFile:String->String;
  public var defs:Array<Dynamic>;
  public var plugins:Dynamic;
  public var fetchTimeout:Int;
  public var dependencyBudget:Int;
  public var reuseInstances:Bool;
  public var stripCRs:Bool;

  public function new() {
    debug = false;
    async = false;
    getFile = function(f:String) return null;
    defs = [];
    plugins = {};
    fetchTimeout = 1000;
    dependencyBudget = 20000;
    reuseInstances = true;
    stripCRs = false;
  }
}

var defaultOptions:ServerOptions = {
  debug: false,
  async: false,
  getFile: function(_f:String, c:Dynamic->Void) {
    if (this.async) c(null, null);
  },
  defs: [],
  plugins: {},
  fetchTimeout: 1000,
  dependencyBudget: 20000,
  reuseInstances: true,
  stripCRs: false
};

var queryTypes:Dynamic = {
  completions: {
    takesFile: true,
    run: findCompletions
  },
  properties: {
    run: findProperties
  },
  type: {
    takesFile: true,
    run: findTypeAt
  },
  documentation: {
    takesFile: true,
    run: findDocs
  },
  definition: {
    takesFile: true,
    run: findDef
  },
  refs: {
    takesFile: true,
    fullFile: true,
    run: findRefs
  },
  rename: {
    takesFile: true,
    fullFile: true,
    run: buildRename
  },
  files: {
    run: listFiles
  }
};

var plugins:Dynamic = {};

function registerPlugin(name:String, init:Dynamic->Dynamic):Void {
  plugins[name] = init;
}

function defineQueryType(name:String, desc:Dynamic):Void {
  queryTypes[name] = desc;
}

function updateText(file:File, text:String, srv:Server):Void {
  file.text = srv.options.stripCRs ? text.replace("\r\n", "\n") : text;
  Infer.withContext(srv.cx, function() {
    file.ast = Infer.parse(file.text, srv.passes, {directSourceFile: file, allowReturnOutsideFunction: true});
  });
  file.lineOffsets = null;
}

function doRequest(srv:Server, doc:Request, c:Dynamic->Void):Void {
  if (doc.query != null && !(doc.query.type in queryTypes)) {
    return c("No query type '" + doc.query.type + "' defined");
  }
  var query = doc.query;
  if (query == null) c(null, {});
  var files = doc.files;
  if (files != null && files.length > 0) ++srv.uses;
  if (files != null) {
    for (i in 0...files.length) {
      var file = files[i];
      if (file.type == "delete") {
        srv.delFile(file.name);
      } else {
        ensureFile(srv, file.name, null, file.type == "full" ? file.text : null);
      }
    }
  }
  var timeBudget:Array<Int> = doc.timeout != null && typeof doc.timeout == "number" ? [doc.timeout] : null;
  if (query == null) {
    analyzeAll(srv, timeBudget, function() {});
    return;
  }
  var queryType = queryTypes[query.type];
  if (queryType.takesFile) {
    if (typeof query.file != "String") return c(".query.file must be a string");
    if (!StringTools.startsWith(query.file, "#")) ensureFile(srv, query.file, null);
  }
  analyzeAll(srv, timeBudget, function(err:Dynamic) {
    if (err != null) return c(err);
    var file:File = queryType.takesFile ? resolveFile(srv, files, query.file) : null;
    if (queryType.fullFile && file != null && file.type == "part") {
      return c("Can't run a " + query.type + " query on a file fragment");
    }
    function run() {
      var result:Dynamic;
      try {
        result = queryType.run(srv, query, file);
      } catch (e:Dynamic) {
        if (srv.options.debug && e.name != "TernError") {
          console.error(e.stack);
        }
        return c(e);
      }
      c(null, result);
    }
    Infer.withContext(srv.cx, timeBudget != null ? function() {
      Infer.withTimeout(timeBudget[0], run);
    } : run);
  });
}

function analyzeFile(srv:Server, file:File):File {
  Infer.withContext(srv.cx, function() {
    file.scope = srv.cx.topScope;
    srv.signal("beforeLoad", file);
    Infer.analyze(file.ast, file.name, file.scope, srv.passes);
    srv.signal("afterLoad", file);
  });
  return file;
}

function ensureFile(srv:Server, name:String, parent:String, text:String):Void {
  var known = srv.findFile(name);
  if (known != null) {
    if (text != null) {
      if (known.scope != null) {
        srv.needsPurge.push(name);
        known.scope = null;
      }
      updateText(known, text, srv);
    }
    if (parentDepth(srv, known.parent) > parentDepth(srv, parent)) {
      known.parent = parent;
      if (known.excluded) known.excluded = null;
    }
    return;
  }
  var file = new File(name, parent);
  srv.files.push(file);
  srv.fileMap[name] = file;
  if (text != null) {
    updateText(file, text, srv);
  } else if (srv.options.async) {
    srv.startAsyncAction();
    srv.options.getFile(name, function(err:Dynamic, text:String) {
      updateText(file, text != null ? text : "", srv);
      srv.finishAsyncAction(err);
    });
  } else {
    updateText(file, srv.options.getFile(name) != null ? srv.options.getFile(name) : "", srv);
  }
}

function fetchAll(srv:Server, c:Dynamic->Void):Void {
  var done = true;
  var returned = false;
  srv.files.forEach(function(file:File) {
    if (file.text != null) return;
    if (srv.options.async) {
      done = false;
      srv.options.getFile(file.name, function(err:Dynamic, text:String) {
        if (err != null && !returned) {
          returned = true;
          return c(err);
        }
        updateText(file, text != null ? text : "", srv);
        fetchAll(srv, c);
      });
    } else {
      try {
        updateText(file, srv.options.getFile(file.name) != null ? srv.options.getFile(file.name) : "", srv);
      } catch (e:Dynamic) {
        return c(e);
      }
    }
  });
  if (done) c();
}

function waitOnFetch(srv:Server, timeBudget:Array<Int>, c:Dynamic->Void):Void {
  var done = function() {
    srv.off("everythingFetched", done);
    clearTimeout(timeout);
    analyzeAll(srv, timeBudget, c);
  };
  srv.on("everythingFetched", done);
  var timeout = Timer.delay(done, srv.options.fetchTimeout);
}

function analyzeAll(srv:Server, timeBudget:Array<Int>, c:Dynamic->Void):Void {
  if (srv.pending > 0) return waitOnFetch(srv, timeBudget, c);
  var e = srv.fetchError;
  if (e != null) {
    srv.fetchError = null;
    return c(e);
  }
  if (srv.needsPurge.length > 0) {
    Infer.withContext(srv.cx, function() {
      Infer.purge(srv.needsPurge);
      srv.needsPurge.length = 0;
    });
  }
  var done = true;
  for (i in 0...srv.files.length) {
    var toAnalyze:Array<File> = [];
    for (j in i...srv.files.length) {
      var file = srv.files[j];
      if (file.text == null) done = false;
      else if (file.scope == null && !file.excluded) toAnalyze.push(file);
    }
    toAnalyze.sort(function(a:File, b:File) {
      return parentDepth(srv, a.parent) - parentDepth(srv, b.parent);
    });
    for (j in 0...toAnalyze.length) {
      var file = toAnalyze[j];
      if (file.parent != null && !chargeOnBudget(srv, file)) {
        file.excluded = true;
      } else if (timeBudget != null) {
        var startTime = Date.now();
        Infer.withTimeout(timeBudget[0], function() {
          analyzeFile(srv, file);
        });
        timeBudget[0] -= Date.now() - startTime;
      } else {
        analyzeFile(srv, file);
      }
    }
  }
  if (done) c();
  else waitOnFetch(srv, timeBudget, c);
}

function firstLine(str:String):String {
  var end = str.indexOf("\n");
  if (end < 0) return str;
  return str.substring(0, end);
}

function findMatchingPosition(line:String, file:String, near:Int):Int {
  var pos = Math.max(0, near - 500);
  var closest:Int = null;
  if (!StringTools.trim(line).isEmpty()) {
    for (;;) {
      var found = file.indexOf(line, pos);
      if (found < 0 || found > near + 500) break;
      if (closest == null || Math.abs(closest - near) > Math.abs(found - near)) closest = found;
      pos = found + line.length;
    }
  }
  return closest;
}

function scopeDepth(s:infer.Scope):Int {
  var i:Int = 0;
  while (s != null) {
    ++i;
    s = s.prev;
  }
  return i;
}

function ternError(msg:String):Dynamic {
  var err = new Error(msg);
  err.name = "TernError";
  return err;
}

function resolveFile(srv:Server, localFiles:Array<Dynamic>, name:String):File {
  var isRef = name.match("#(\\d+)");
  if (isRef == null) return srv.findFile(name);
  var file:Dynamic = localFiles[Std.parseInt(isRef[1])];
  if (file == null || file.type == "delete") throw ternError("Reference to unknown file " + name);
  if (file.type == "full") return srv.findFile(file.name);
  var realFile = file.backing = srv.findFile(file.name);
  var offset:Int;
  file.offset = offset = resolvePos(realFile, file.offsetLines == null ? file.offset : {line: file.offsetLines, ch: 0}, true);
  var line = firstLine(file.text);
  var foundPos:Int = findMatchingPosition(line, realFile.text, offset);
  var pos:Int = foundPos == null ? Math.max(0, realFile.text.lastIndexOf("\n", offset)) : foundPos;
  var inObject:Dynamic = null;
  var atFunction:Bool = false;
  Infer.withContext(srv.cx, function() {
    Infer.purge(file.name, pos, pos + file.text.length);
    var text = file.text;
    var m:Match = text.match("(?:\"([^\"]*)\"|([\\w$]+))\\s*:\\s*function\\b");
    if (m != null) {
      var objNode:walk.Node = walk.findNodeAround(file.backing.ast, pos, "ObjectExpression");
      if (objNode != null && objNode.node.objType != null) {
        inObject = {type: objNode.node.objType, prop: m[2] != null ? m[2] : m[1]};
      }
    }
    if (foundPos && (m = line.match("^(.*?)\\bfunction\\b"))) {
      var cut = m[1].length;
      var white = "";
      for (i in 0...cut) white += " ";
      text = white + text.substring(cut);
      atFunction = true;
    }
    var scopeStart = Infer.scopeAt(realFile.ast, pos, realFile.scope);
    var scopeEnd = Infer.scopeAt(realFile.ast, pos + text.length, realFile.scope);
    var scope:infer.Scope = scopeDepth(scopeStart) < scopeDepth(scopeEnd) ? scopeEnd : scopeStart;
    file.scope = scope;
    file.ast = Infer.parse(text, srv.passes, {directSourceFile: file, allowReturnOutsideFunction: true});
    Infer.analyze(file.ast, file.name, scope, srv.passes);
    if (inObject != null || atFunction) {
      var newInner:infer.Scope = Infer.scopeAt(file.ast, line.length, scopeStart);
      if (newInner.fnType == null) break;
      if (inObject != null) {
        var prop:infer.Property = inObject.type.getProp(inObject.prop);
        prop.addType(newInner.fnType);
      } else if (atFunction) {
        var inner:infer.Scope = Infer.scopeAt(realFile.ast, pos + line.length, realFile.scope);
        if (inner == scopeStart || inner.fnType == null) break;
        var fOld = inner.fnType;
        var fNew = newInner.fnType;
        if (fNew == null || (fNew.name != fOld.name && fOld.name != null)) break;
        for (i in 0...Math.min(fOld.args.length, fNew.args.length)) fOld.args[i].propagate(fNew.args[i]);
        fOld.self.propagate(fNew.self);
        fNew.retval.propagate(fOld.retval);
      }
    }
  });
  return file;
}

function astSize(node:acorn.Node):Int {
  var size:Int = 0;
  walk.simple(node, {
    Expression: function() {
      ++size;
    }
  });
  return size;
}

function parentDepth(srv:Server, parent:String):Int {
  var depth:Int = 0;
  while (parent != null) {
    parent = srv.findFile(parent).parent;
    ++depth;
  }
  return depth;
}

function budgetName(srv:Server, file:File):String {
  for (;;) {
    var parent = srv.findFile(file.parent);
    if (parent.parent == null) break;
    file = parent;
  }
  return file.name;
}

function chargeOnBudget(srv:Server, file:File):Bool {
  var bName = budgetName(srv, file);
  var size = astSize(file.ast);
  var known:Int = srv.budgets[bName];
  if (known == null) known = srv.budgets[bName] = srv.options.dependencyBudget;
  if (known < size) return false;
  srv.budgets[bName] = known - size;
  return true;
}

function isPosition(val:Dynamic):Bool {
  return typeof val == "number" || (typeof val == "object" && typeof val.line == "number" && typeof val.ch == "number");
}

function invalidDoc(doc:Request):Dynamic {
  if (doc.query != null) {
    if (typeof doc.query.type != "String") return ".query.type must be a string";
    if (doc.query.start != null && !isPosition(doc.query.start)) return ".query.start must be a position";
    if (doc.query.end != null && !isPosition(doc.query.end)) return ".query.end must be a position";
  }
  if (doc.files != null) {
    if (!Type.is(doc.files, Array)) return "Files property must be an array";
    for (i in 0...doc.files.length) {
      var file:Dynamic = doc.files[i];
      if (typeof file != "object") return ".files[n] must be objects";
      else if (typeof file.name != "String") return ".files[n].name must be a string";
      else if (file.type == "delete") continue;
      else if (typeof file.text != "String") return ".files[n].text must be a string";
      else if (file.type == "part") {
        if (!isPosition(file.offset) && typeof file.offsetLines != "number") {
          return ".files[n].offset must be a position";
        }
      } else if (file.type != "full") return ".files[n].type must be \"full\" or \"part\"";
    }
  }
}

var offsetSkipLines:Int = 25;

function findLineStart(file:File, line:Int):Int {
  var text = file.text;
  var offsets = file.lineOffsets;
  if (offsets == null) {
    offsets = file.lineOffsets = [0];
  }
  var pos:Int = 0;
  var curLine:Int = 0;
  var storePos:Int = Math.min(Math.floor(line / offsetSkipLines), offsets.length - 1);
  pos = offsets[storePos];
  curLine = storePos * offsetSkipLines;
  while (curLine < line) {
    ++curLine;
    pos = text.indexOf("\n", pos) + 1;
    if (pos == 0) return null;
    if (curLine % offsetSkipLines == 0) offsets.push(pos);
  }
  return pos;
}

var resolvePos = function(file:File, pos:Dynamic, tolerant:Bool = false):Int {
  if (typeof pos != "number") {
    var lineStart = findLineStart(file, pos.line);
    if (lineStart == null) {
      if (tolerant) pos = file.text.length;
      else throw ternError("File doesn't contain a line " + pos.line);
    } else {
      pos = lineStart + pos.ch;
    }
  }
  if (pos > file.text.length) {
    if (tolerant) pos = file.text.length;
    else throw ternError("Position " + pos + " is outside of file.");
  }
  return pos;
};

function asLineChar(file:File, pos:Int):{line:Int, ch:Int} {
  if (file == null) return {line: 0, ch: 0};
  var offsets = file.lineOffsets;
  if (offsets == null) {
    offsets = file.lineOffsets = [0];
  }
  var text = file.text;
  var line:Int = 0;
  var lineStart:Int = 0;
  for (i in offsets.length - 1...0... -1) {
    if (offsets[i] <= pos) {
      line = i * offsetSkipLines;
      lineStart = offsets[i];
    }
  }
  for (;;) {
    var eol = text.indexOf("\n", lineStart);
    if (eol >= pos || eol < 0) break;
    lineStart = eol + 1;
    ++line;
  }
  return {line: line, ch: pos - lineStart};
}

var outputPos = function(query:Query, file:File, pos:Int):Dynamic {
  if (query.lineCharPositions) {
    var out = asLineChar(file, pos);
    if (file.type == "part") out.line += file.offsetLines != null ? file.offsetLines : asLineChar(file.backing, file.offset).line;
    return out;
  } else {
    return pos + (file.type == "part" ? file.offset : 0);
  }
};

function clean(obj:Dynamic):Dynamic {
  for (prop in obj) if (obj[prop] == null) delete obj[prop];
  return obj;
}

function maybeSet(obj:Dynamic, prop:String, val:Dynamic):Void {
  if (val != null) obj[prop] = val;
}

function compareCompletions(a:Dynamic, b:Dynamic):Int {
  if (typeof a != "String") {
    a = a.name;
    b = b.name;
  }
  var aUp = StringTools.startsWith(a, StringTools.upFirst(a));
  var bUp = StringTools.startsWith(b, StringTools.upFirst(b));
  if (aUp == bUp) return a < b ? -1 : a == b ? 0 : 1;
  else return aUp ? 1 : -1;
}

function isStringAround(node:acorn.Node, start:Int, end:Int):Bool {
  return node.type == "Literal" && Type.is(node.value, String) && node.start == start - 1 && node.end <= end + 1;
}

function pointInProp(objNode:acorn.Node, point:Int):acorn.Node {
  for (i in 0...objNode.properties.length) {
    var curProp = objNode.properties[i];
    if (curProp.key.start <= point && curProp.key.end >= point) return curProp;
  }
}

var jsKeywords:Array<String> = ["break", "do", "instanceof", "typeof", "case", "else", "new", "var", "catch", "finally", "return", "void", "continue", "for", "switch", "while", "debugger", "function", "this", "with", "default", "if", "throw", "delete", "in", "try"];

function findCompletions(srv:Server, query:Query, file:File):{start:Dynamic, end:Dynamic, isProperty:Bool, isObjectKey:Bool, completions:Array<Dynamic>} {
  if (query.end == null) throw ternError("missing .query.end field");
  if (srv.passes.completion != null) {
    for (i in 0...srv.passes.completion.length) {
      var result:Dynamic = srv.passes.completion[i](file, query);
      if (result != null) return result;
    }
  }
  var wordStart:Int = resolvePos(file, query.end);
  var wordEnd:Int = wordStart;
  var text = file.text;
  while (wordStart > 0 && acorn.isIdentifierChar(text.charCodeAt(wordStart - 1))) --wordStart;
  if (query.expandWordForward != false) {
    while (wordEnd < text.length && acorn.isIdentifierChar(text.charCodeAt(wordEnd))) ++wordEnd;
  }
  var word = text.substring(wordStart, wordEnd);
  var completions:Array<Dynamic> = [];
  var ignoreObj:Dynamic = null;
  if (query.caseInsensitive) word = word.toLowerCase();
  var wrapAsObjs = query.types != null || query.depths != null || query.docs != null || query.urls != null || query.origins != null;
  function gather(prop:String, obj:infer.Obj, depth:Int, addInfo:Dynamic->Void) {
    if ((objLit != null || query.omitObjectPrototype != false) && obj == srv.cx.protos.Object && !word) return;
    if (query.filter != false && word != null && (query.caseInsensitive ? prop.toLowerCase() : prop).indexOf(word) != 0) return;
    if (ignoreObj != null && ignoreObj.props.hasOwnProperty(prop)) return;
    for (i in 0...completions.length) {
      var c:Dynamic = completions[i];
      if ((wrapAsObjs ? c.name : c) == prop) return;
    }
    var rec:Dynamic = wrapAsObjs ? {name: prop} : prop;
    completions.push(rec);
    if (obj != null && (query.types != null || query.docs != null || query.urls != null || query.origins != null)) {
      var val:infer.Property = obj.props[prop];
      Infer.resetGuessing();
      var type:Type = val.getType();
      rec.guess = Infer.didGuess();
      if (query.types != null) rec.type = Infer.toString(val);
      if (query.docs != null) maybeSet(rec, "doc", val.doc != null ? val.doc : (type != null ? type.doc : null));
      if (query.urls != null) maybeSet(rec, "url", val.url != null ? val.url : (type != null ? type.url : null));
      if (query.origins != null) maybeSet(rec, "origin", val.origin != null ? val.origin : (type != null ? type.origin : null));
    }
    if (query.depths != null) rec.depth = depth;
    if (wrapAsObjs && addInfo != null) addInfo(rec);
  }
  var hookname:String = null;
  var prop:String = null;
  var objType:infer.Obj = null;
  var isKey:Bool = false;
  var exprAt:infer.Expr = Infer.findExpressionAround(file.ast, null, wordStart, file.scope);
  var memberExpr:Dynamic = null;
  var objLit:infer.Expr = null;
  if (exprAt != null) {
    if (exprAt.node.type == "MemberExpression" && exprAt.node.object.end < wordStart) {
      memberExpr = exprAt;
    } else if (isStringAround(exprAt.node, wordStart, wordEnd)) {
      var parent = Infer.parentNode(exprAt.node, file.ast);
      if (parent.type == "MemberExpression" && parent.property == exprAt.node) {
        memberExpr = {node: parent, state: exprAt.state};
      }
    } else if (exprAt.node.type == "ObjectExpression") {
      var objProp:acorn.Node = pointInProp(exprAt.node, wordEnd);
      if (objProp != null) {
        objLit = exprAt;
        prop = isKey = objProp.key.name;
      } else if (word == null && !StringTools.endsWith(file.text.substring(0, wordStart), ": ")) {
        objLit = exprAt;
        prop = isKey = true;
      }
    }
  }
  if (objLit != null) {
    objType = Infer.typeFromContext(file.ast, objLit);
    ignoreObj = objLit.node.objType;
  } else if (memberExpr != null) {
    prop = memberExpr.node.property;
    prop = prop.type == "Literal" ? prop.value.substring(1) : prop.name;
    memberExpr.node = memberExpr.node.object;
    objType = Infer.expressionType(memberExpr);
  } else if (text.charAt(wordStart - 1) == ".") {
    var pathStart:Int = wordStart - 1;
    while (pathStart > 0 && (text.charAt(pathStart - 1) == "." || acorn.isIdentifierChar(text.charCodeAt(pathStart - 1)))) pathStart--;
    var path:String = text.substring(pathStart, wordStart - 1);
    if (path != null) {
      objType = def.parsePath(path, file.scope).getObjType();
      prop =
      prop = word;
    }
  }

  if (prop != null) {
    srv.cx.completingProperty = prop;

    if (objType != null) Infer.forAllPropertiesOf(objType, gather);

    if (completions.length == 0 && query.guess != false && objType != null && objType.guessProperties != null) {
      objType.guessProperties(function(p:String, o:infer.Obj, d:Int) {
        if (p != prop && p != "✖") gather(p, o, d);
      });
    }
    if (completions.length == 0 && word.length >= 2 && query.guess != false) {
      for (prop in srv.cx.props) {
        gather(prop, srv.cx.props[prop][0], 0);
      }
    }
    hookname = "memberCompletion";
  } else {
    Infer.forAllLocalsAt(file.ast, wordStart, file.scope, gather);
    if (query.includeKeywords) {
      jsKeywords.forEach(function(kw:String) {
        gather(kw, null, 0, function(rec:Dynamic) {
          rec.isKeyword = true;
        });
      });
    }
    hookname = "variableCompletion";
  }
  if (srv.passes[hookname] != null) {
    srv.passes[hookname].forEach(function(hook:Dynamic) {
      hook(file, wordStart, wordEnd, gather);
    });
  }

  if (query.sort != false) completions.sort(compareCompletions);
  srv.cx.completingProperty = null;

  return {
    start: outputPos(query, file, wordStart),
    end: outputPos(query, file, wordEnd),
    isProperty: prop != null,
    isObjectKey: isKey,
    completions: completions
  };
}

function findProperties(srv:Server, query:Query):{completions:Array<String>} {
  var prefix = query.prefix;
  var found:Array<String> = [];
  for (prop in srv.cx.props) {
    if (prop != "<i>" && (prefix == null || prop.indexOf(prefix) == 0)) found.push(prop);
  }
  if (query.sort != false) found.sort(compareCompletions);
  return {completions: found};
}

var findExpr = exports.findQueryExpr = function(file:File, query:Query, wide:Bool = false):{node:acorn.Node, state:infer.Scope} {
  if (query.end == null) throw ternError("missing .query.end field");

  if (query.variable != null) {
    var scope = Infer.scopeAt(file.ast, resolvePos(file, query.end), file.scope);
    return {
      node: {type: "Identifier", name: query.variable, start: query.end, end: query.end + 1},
      state: scope
    };
  } else {
    var start = query.start != null ? resolvePos(file, query.start) : null;
    var end = resolvePos(file, query.end);
    var expr = Infer.findExpressionAt(file.ast, start, end, file.scope);
    if (expr != null) return expr;
    expr = Infer.findExpressionAround(file.ast, start, end, file.scope);
    if (expr != null && (expr.node.type == "ObjectExpression" || wide || (start == null ? end : start) - expr.node.start < 20 || expr.node.end - end < 20)) {
      return expr;
    }
    return null;
  }
};

function findExprOrThrow(file:File, query:Query, wide:Bool = false):{node:acorn.Node, state:infer.Scope} {
  var expr = findExpr(file, query, wide);
  if (expr != null) return expr;
  throw ternError("No expression at the given position.");
}

function ensureObj(tp:Type):infer.Obj {
  if (tp == null || !(tp = tp.getType()) || !(tp instanceof infer.Obj)) return null;
  return tp;
}

function findExprType(srv:Server, query:Query, file:File, expr:infer.Expr):Type {
  var type:Type = null;
  if (expr != null) {
    Infer.resetGuessing();
    type = Infer.expressionType(expr);
  }
  if (srv.passes["typeAt"] != null) {
    var pos = resolvePos(file, query.end);
    srv.passes["typeAt"].forEach(function(hook:Dynamic) {
      type = hook(file, pos, expr, type);
    });
  }
  if (type == null) throw ternError("No type found at the given position.");

  var objProp:acorn.Node = null;
  if (expr.node.type == "ObjectExpression" && query.end != null && (objProp = pointInProp(expr.node, resolvePos(file, query.end)))) {
    var name = objProp.key.name;
    var fromCx:infer.Obj = ensureObj(Infer.typeFromContext(file.ast, expr));
    if (fromCx != null && fromCx.hasProp(name)) {
      type = fromCx.hasProp(name);
    } else {
      var fromLocal:infer.Obj = ensureObj(type);
      if (fromLocal != null && fromLocal.hasProp(name)) {
        type = fromLocal.hasProp(name);
      }
    }
  }
  return type;
};

function findTypeAt(srv:Server, query:Query, file:File):{guess:Bool, type:String, name:String, exprName:String} {
  var expr:infer.Expr = findExpr(file, query);
  var exprName:String = null;
  var type:Type = findExprType(srv, query, file, expr);
  var exprType = type;
  if (query.preferFunction) {
    type = type.getFunctionType() != null ? type.getFunctionType() : type.getType();
  } else {
    type = type.getType();
  }

  if (expr != null) {
    if (expr.node.type == "Identifier") {
      exprName = expr.node.name;
    } else if (expr.node.type == "MemberExpression" && !expr.node.computed) {
      exprName = expr.node.property.name;
    }
  }

  if (query.depth != null && typeof query.depth != "number") {
    throw ternError(".query.depth must be a number");
  }

  var result = {
    guess: Infer.didGuess(),
    type: Infer.toString(exprType, query.depth),
    name: type != null ? type.name : null,
    exprName: exprName
  };
  if (type != null) storeTypeDocs(type, result);
  if (result.doc == null && exprType.doc != null) result.doc = exprType.doc;

  return clean(result);
}

function findDocs(srv:Server, query:Query, file:File):{url:String, doc:String, type:String} {
  var expr:infer.Expr = findExpr(file, query);
  var type:Type = findExprType(srv, query, file, expr);
  var result = {url: type.url, doc: type.doc, type: Infer.toString(type)};
  var inner:Type = type.getType();
  if (inner != null) storeTypeDocs(inner, result);
  return clean(result);
}

function storeTypeDocs(type:Type, out:Dynamic):Void {
  if (out.url == null) out.url = type.url;
  if (out.doc == null) out.doc = type.doc;
  if (out.origin == null) out.origin = type.origin;
  var ctor:infer.Property = null;
  var boring = Infer.cx().protos;
  if (out.url == null && out.doc == null && type.proto != null && (ctor = type.proto.hasCtor) && type.proto != boring.Object && type.proto != boring.Function && type.proto != boring.Array) {
    out.url = ctor.url;
    out.doc = ctor.doc;
  }
}

var getSpan = exports.getSpan = function(obj:Dynamic):Dynamic {
  if (obj.origin == null) return null;
  if (obj.originNode != null) {
    var node = obj.originNode;
    if (StringTools.startsWith(node.type, "Function") && node.id != null) node = node.id;
    return {origin: obj.origin, node: node};
  }
  if (obj.span != null) return {origin: obj.origin, span: obj.span};
};

var storeSpan = exports.storeSpan = function(srv:Server, query:Query, span:Dynamic, target:Dynamic):Void {
  target.origin = span.origin;
  if (span.span != null) {
    var m:Match = span.span.match("(\\d+)\[(\\d+):(\\d+)\]-(\\d+)\[(\\d+):(\\d+)\]");
    target.start = query.lineCharPositions ? {line: Std.parseInt(m[2]), ch: Std.parseInt(m[3])} : Std.parseInt(m[1]);
    target.end = query.lineCharPositions ? {line: Std.parseInt(m[5]), ch: Std.parseInt(m[6])} : Std.parseInt(m[4]);
  } else {
    var file = srv.findFile(span.origin);
    target.start = outputPos(query, file, span.node.start);
    target.end = outputPos(query, file, span.node.end);
  }
};

function findDef(srv:Server, query:Query, file:File):{url:String, doc:String, origin:String, start:Dynamic, end:Dynamic, file:String, contextOffset:Int, context:String} {
  var expr:infer.Expr = findExpr(file, query);
  var type:Type = findExprType(srv, query, file, expr);
  if (Infer.didGuess()) return {};

  var span = getSpan(type);
  var result = {url: type.url, doc: type.doc, origin: type.origin};

  if (type.types != null) {
    for (i in type.types.length - 1...0... -1) {
      var tp:Type = type.types[i];
      storeTypeDocs(tp, result);
      if (span == null) span = getSpan(tp);
    }
  }

  if (span != null && span.node != null) { // refers to a loaded file
    var spanFile:File = span.node.sourceFile != null ? span.node.sourceFile : srv.findFile(span.origin);
    var start = outputPos(query, spanFile, span.node.start);
    var end = outputPos(query, spanFile, span.node.end);
    result.start = start;
    result.end = end;
    result.file = span.origin;
    var cxStart = Math.max(0, span.node.start - 50);
    result.contextOffset = span.node.start - cxStart;
    result.context = spanFile.text.substring(cxStart, cxStart + 50);
  } else if (span != null) { // external
    result.file = span.origin;
    storeSpan(srv, query, span, result);
  }
  return clean(result);
}

function findRefsToVariable(srv:Server, query:Query, file:File, expr:infer.Expr, checkShadowing:String):{refs:Array<{file:String, start:Dynamic, end:Dynamic}>, type:String, name:String} {
  var name = expr.node.name;

  var scope:infer.Scope = expr.state;
  while (scope != null && !scope.props.hasOwnProperty(name)) {
    scope = scope.prev;
  }
  if (scope == null) throw ternError("Could not find a definition for " + name + " " + (srv.cx.topScope.props.hasOwnProperty("x") ? "true" : "false"));

  var type:String = null;
  var refs:Array<{file:String, start:Dynamic, end:Dynamic}> = [];
  function storeRef(file:File):Dynamic->Void {
    return function(node:acorn.Node, scopeHere:infer.Scope) {
      if (checkShadowing != null) {
        for (var s = scopeHere; s != scope; s = s.prev) {
          var exists:infer.Property = s.hasProp(checkShadowing);
          if (exists != null) {
            throw ternError("Renaming `" + name + "` to `" + checkShadowing + "` would make a variable at line " + (asLineChar(file, node.start).line + 1) + " point to the definition at line " + (asLineChar(file, exists.name.start).line + 1));
          }
        }
      }
      refs.push({
        file: file.name,
        start: outputPos(query, file, node.start),
        end: outputPos(query, file, node.end)
      });
    };
  }

  if (scope.originNode != null) {
    type = "local";
    if (checkShadowing != null) {
      for (var prev = scope.prev; prev != null; prev = prev.prev) {
        if (prev.props.hasOwnProperty(checkShadowing)) break;
      }
      if (prev != null) {
        Infer.findRefs(scope.originNode, scope, checkShadowing, prev, function(node:acorn.Node) {
          throw ternError("Renaming `" + name + "` to `" + checkShadowing + "` would shadow the definition used at line " + (asLineChar(file, node.start).line + 1));
        });
      }
    }
    Infer.findRefs(scope.originNode, scope, name, scope, storeRef(file));
  } else {
    type = "global";
    for (i in 0...srv.files.length) {
      var cur = srv.files[i];
      Infer.findRefs(cur.ast, cur.scope, name, scope, storeRef(cur));
    }
  }

  return {refs: refs, type: type, name: name};
}

function findRefsToProperty(srv:Server, query:Query, expr:infer.Expr, prop:acorn.Node):{refs:Array<{file:String, start:Dynamic, end:Dynamic}>, name:String} {
  var objType:infer.Obj = Infer.expressionType(expr).getObjType();
  if (objType == null) throw ternError("Couldn't determine type of base object.");

  var refs:Array<{file:String, start:Dynamic, end:Dynamic}> = [];
  function storeRef(file:File):Dynamic->Void {
    return function(node:acorn.Node) {
      refs.push({
        file: file.name,
        start: outputPos(query, file, node.start),
        end: outputPos(query, file, node.end)
      });
    };
  }
  for (i in 0...srv.files.length) {
    var cur = srv.files[i];
    Infer.findPropRefs(cur.ast, cur.scope, objType, prop.name, storeRef(cur));
  }

  return {refs: refs, name: prop.name};
}

function findRefs(srv:Server, query:Query, file:File):{refs:Array<{file:String, start:Dynamic, end:Dynamic}>, type:String, name:String} {
  var expr = findExprOrThrow(file, query, true);
  if (expr.node.type == "Identifier") {
    return findRefsToVariable(srv, query, file, expr);
  } else if (expr.node.type == "MemberExpression" && !expr.node.computed) {
    var p = expr.node.property;
    expr.node = expr.node.object;
    return findRefsToProperty(srv, query, expr, p);
  } else if (expr.node.type == "ObjectExpression") {
    var pos = resolvePos(file, query.end);
    for (i in 0...expr.node.properties.length) {
      var k = expr.node.properties[i].key;
      if (k.start <= pos && k.end >= pos) {
        return findRefsToProperty(srv, query, expr, k);
      }
    }
  }
  throw ternError("Not at a variable or property name.");
}

function buildRename(srv:Server, query:Query, file:File):{files:Array<String>, changes:Array<{file:String, start:Dynamic, end:Dynamic, text:String}>, name:String, type:String} {
  if (typeof query.newName != "String") throw ternError(".query.newName should be a string");
  var expr = findExprOrThrow(file, query);
  if (expr == null || expr.node.type != "Identifier") throw ternError("Not at a variable.");

  var data = findRefsToVariable(srv, query, file, expr, query.newName);
  var refs = data.refs;
  delete data.refs;
  data.files = srv.files.map(function(f:File) return f.name);

  var changes = data.changes = [];
  for (i in 0...refs.length) {
    var use = refs[i];
    use.text = query.newName;
    changes.push(use);
  }

  return data;
}

function listFiles(srv:Server):{files:Array<String>} {
  return {files: srv.files.map(function(f:File) return f.name)};
}

exports.version = "0.11.1";