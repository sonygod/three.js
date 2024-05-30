import js.Browser;
import js.html.Document;
import js.html.Element;
import js.html.Node;
import js.html.Window;
import js.lib.DocumentData;
import js.node.EventLoop;
import js.node.Fs;
import js.node.Timer;
import js.node.process;
import js.node.timers;

class CodeMirrorTernServer {
    var options: { defs: dynamic; plugins: dynamic; getFile: dynamic; fileFilter: dynamic; switchToDoc: dynamic; showError: dynamic; completionTip: dynamic; typeTip: dynamic; responseFilter: dynamic; useWorker: dynamic; workerScript: dynamic; workerDeps: dynamic; };
    var docs: Map<String, { doc: js.html.Document; name: String; changed: ?Null<Int>; }>;
    var server: dynamic;
    var trackChange: (doc: js.html.Document, change: dynamic) -> Void;
    var cachedArgHints: ?Null<{ start: js.html.Position; type: dynamic; name: String; guess: dynamic; doc: js.html.Document; }>;
    var activeArgHints: ?Null<Node>;
    var jumpStack: Array<{ file: String; start: js.html.Position; end: js.html.Position; }>;

    public function new(options: { defs: dynamic; plugins: dynamic; getFile: dynamic; fileFilter: dynamic; switchToDoc: dynamic; showError: dynamic; completionTip: dynamic; typeTip: dynamic; responseFilter: dynamic; useWorker: dynamic; workerScript: dynamic; workerDeps: dynamic; }) {
        this.options = options;
        var plugins = this.options.plugins || (this.options.plugins = {});
        if (!plugins.doc_comment) plugins.doc_comment = true;
        this.docs = Map.create();
        if (this.options.useWorker) {
            this.server = new WorkerServer(this);
        } else {
            this.server = new js.tern.Server({
                getFile: function(name, c) { return getFile(this, name, c); },
                async: true,
                defs: this.options.defs || [],
                plugins: plugins
            });
        }
        this.trackChange = function(doc, change) { trackChange(this, doc, change); };

        this.cachedArgHints = null;
        this.activeArgHints = null;
        this.jumpStack = [];
    }

    public function addDoc(name: String, doc: js.html.Document): { doc: js.html.Document; name: String; changed: ?Null<Int>; } {
        var data = {doc: doc, name: name, changed: null};
        this.server.addFile(name, docValue(this, data));
        doc.on("change", this.trackChange);
        return this.docs[name] = data;
    }

    public function delDoc(id: String) {
        var found = resolveDoc(this, id);
        if (!found) return;
        doc.off("change", this.trackChange);
        delete this.docs[found.name];
        this.server.delFile(found.name);
    }

    public function hideDoc(id: String) {
        closeArgHints(this);
        var found = resolveDoc(this, id);
        if (found && found.changed) sendDoc(this, found);
    }

    public function complete(cm: js.html.Document) {
        cm.showHint({hint: this.getHint});
    }

    public function showType(cm: js.html.Document, pos: js.html.Position, c: dynamic) { showContextInfo(this, cm, pos, "type", c); }

    public function showDocs(cm: js.html.Document, pos: js.html.Position, c: dynamic) { showContextInfo(this, cm, pos, "documentation", c); }

    public function updateArgHints(cm: js.html.Document) { updateArgHints(this, cm); }

    public function jumpToDef(cm: js.html.Document) { jumpToDef(this, cm); }

    public function jumpBack(cm: js.html.Document) { jumpBack(this, cm); }

    public function rename(cm: js.html.Document) { rename(this, cm); }

    public function selectName(cm: js.html.Document) { selectName(this, cm); }

    public function request (cm: js.html.Document, query: dynamic, c: dynamic, pos: js.html.Position) {
        var doc = findDoc(this, cm.getDoc());
        var request = buildRequest(this, doc, query, pos);
        var extraOptions = request.query && this.options.queryOptions && this.options.queryOptions[request.query.type];
        if (extraOptions) for (var prop in extraOptions) request.query[prop] = extraOptions[prop];

        this.server.request(request, function (error, data) {
            if (!error && this.options.responseFilter)
                data = this.options.responseFilter(doc, query, request, error, data);
            c(error, data);
        });
    }

    public function destroy() {
        closeArgHints(this);
        if (this.worker) {
            this.worker.terminate();
            this.worker = null;
        }
    }

    function getFile(ts, name, c) {
        var buf = ts.docs[name];
        if (buf)
            c(docValue(ts, buf));
        else if (ts.options.getFile)
            ts.options.getFile(name, c);
        else
            c(null);
    }

    function findDoc(ts, doc, name) {
        for (var n in ts.docs) {
            var cur = ts.docs[n];
            if (cur.doc == doc) return cur;
        }
        if (!name) for (var i = 0;; ++i) {
            n = "[doc" + (i || "") + "]";
            if (!ts.docs[n]) { name = n; break; }
        }
        return ts.addDoc(name, doc);
    }

    function resolveDoc(ts, id) {
        if (typeof id == "string") return ts.docs[id];
        if (id instanceof js.html.Document) id = id.getDoc();
        if (id instanceof js.html.Document) return findDoc(ts, id);
    }

    function trackChange(ts, doc, change) {
        var data = findDoc(ts, doc);

        var argHints = ts.cachedArgHints;
        if (argHints && argHints.doc == doc && cmpPos(argHints.start, change.to) >= 0)
            ts.cachedArgHints = null;

        var changed = data.changed;
        if (changed == null)
            data.changed = changed = {from: change.from.line, to: change.from.line};
        var end = change.from.line + (change.text.length - 1);
        if (change.from.line < changed.to) changed.to = changed.to - (change.to.line - end);
        if (end >= changed.to) changed.to = end + 1;
        if (changed.from > change.from.line) changed.from = change.from.line;

        if (doc.lineCount() > bigDoc && change.to - changed.from > 100) setTimeout(function() {
            if (data.changed && data.changed.to - data.changed.from > 100) sendDoc(ts, data);
        }, 200);
    }

    function sendDoc(ts, doc) {
        ts.server.request({files: [{type: "full", name: doc.name, text: docValue(ts, doc)}]}, function(error) {
            if (error) Window.console.error(error);
            else doc.changed = null;
        });
    }

    // Completion

    function hint(ts, cm, c) {
        ts.request(cm, {type: "completions", types: true, docs: true, urls: true}, function(error, data) {
            if (error) return showError(ts, cm, error);
            var completions = [], after = "";
            var from = data.start, to = data.end;
            if (cm.getRange(Pos(from.line, from.ch - 2), from) == "[\"" &&
                cm.getRange(to, Pos(to.line, to.ch + 2)) != "\"]")
                after = "\"]";

            for (var i = 0; i < data.completions.length; ++i) {
                var completion = data.completions[i], className = typeToIcon(completion.type);
                if (data.guess) className += " " + cls + "guess";
                completions.push({text: completion.name + after,
                                  displayText: completion.displayName || completion.name,
                                  className: className,
                                  data: completion});
            }

            var obj = {from: from, to: to, list: completions};
            var tooltip = null;
            cm.on(obj, "close", function() { remove(tooltip); });
            cm.on(obj, "update", function() { remove(tooltip); });
            cm.on(obj, "select", function(cur, node) {
                remove(tooltip);
                var content = ts.options.completionTip ? ts.options.completionTip(cur.data) : cur.data.doc;
                if (content) {
                    tooltip = makeTooltip(node.parentNode.getBoundingClientRect().right + Window.pageXOffset,
                                          node.getBoundingClientRect().top + Window.pageYOffset, content, cm, cls + "hint-doc");
                }
            });
            c(obj);
        });
    }

    function typeToIcon(type) {
        var suffix;
        if (type == "?") suffix = "unknown";
        else if (type == "number" || type == "string" || type == "bool") suffix = type;
        else if (/^fn\(/.test(type)) suffix = "fn";
        else if (/^\[/.test(type)) suffix = "array";
        else suffix = "object";
        return cls + "completion " + cls + "completion-" + suffix;
    }

    // Type queries

    function showContextInfo(ts, cm, pos, queryName, c) {
        ts.request(cm, queryName, function(error, data) {
            if (error) return showError(ts, cm, error);
            if (ts.options.typeTip) {
                var tip = ts.options.typeTip(data);
            } else {
                var tip = elt("span", null, elt("strong", null, data.type || "not found"));
                if (data.doc)
                    tip.appendChild(Document.createTextNode(" — " + data.doc));
                if (data.url) {
                    tip.appendChild(Document.createTextNode(" "));
                    var child = tip.appendChild(elt("a", null, "[docs]"));
                    child.href = data.url;
                    child.target = "_blank";
                }
            }
            tempTooltip(cm, tip, ts);
            if (c) c();
        }, pos);
    }

    // Maintaining argument hints

    function updateArgHints(ts, cm) {
        closeArgHints(ts);

        if (cm.somethingSelected()) return;
        var state = cm.getTokenAt(cm.getCursor()).state;
        var inner = CodeMirror.innerMode(cm.getMode(), state);
        if (inner.mode.name != "javascript") return;
        var lex = inner.state.lexical;
        if (lex.info != "call") return;

        var ch, argPos = lex.pos || 0, tabSize = cm.getOption("tabSize");
        for (var line = cm.getCursor().line, e = Math.max(0, line - 9), found = false; line >= e; --line) {
            var str = cm.getLine(line), extra = 0;
            for (var pos = 0;;) {
                var tab = str.indexOf("\t", pos);
                if (tab == -1) break;
                extra += tabSize - (tab + extra) % tabSize - 1;
                pos = tab + 1;
            }
            ch = lex.column - extra;
            if (str.charAt(ch) == "(") {found = true; break;}
        }
        if (!found) return;

        var start = Pos(line, ch);
        var cache = ts.cachedArgHints;
        if (cache && cache.doc == cm.getDoc() && cmpPos(start, cache.start) == 0)
            return showArgHints(ts, cm, argPos);

        ts.request(cm, {type: "type", preferFunction: true, end: start}, function(error, data) {
            if (error || !data.type || !(/^fn\(/).test(data.type)) return;
            ts.cachedArgHints = {
                start: start,
                type: parseFnType(data.type),
                name: data.exprName || data.name || "fn",
                guess: data.guess,
                doc: cm.getDoc()
            };
            showArgHints(ts, cm, argPos);
        });
    }

    function showArgHints(ts, cm, pos) {
        closeArgHints(ts);

        var cache = ts.cachedArgHints, tp = cache.type;
        var tip = elt("span", cache.guess ? cls + "fhint-guess" : null,
                      elt("span", cls + "fname", cache.name), "(");
        for (var i = 0; i < tp.args.length; ++i) {
            if (i) tip.appendChild(Document.createTextNode(", "));
            var arg = tp.args[i];
            tip.appendChild(elt("span", cls + "farg" + (i == pos ? " " + cls + "farg-current" : ""), arg.name || "?"));
            if (arg.type != "?") {
                tip.appendChild(Document.createTextNode(":\u00a0"));
                tip.appendChild(elt("span", cls + "type", arg.type));
            }
        }
        tip.appendChild(Document.createTextNode(tp.rettype ? ") ->\u00a0" : ")"));
        if (tp.rettype) tip.appendChild(elt("span", cls + "type", tp.rettype));
        var place = cm.cursorCoords(null, "page");
        var tooltip = ts.activeArgHints = makeTooltip(place.right + 1, place.bottom, tip, cm)
        setTimeout(function() {
            tooltip.clear = onEditorActivity(cm, function() {
                if (ts.activeArgHints == tooltip) closeArgHints(ts) })
        }, 20)
    }

    function parseFnType(text) {
        var args = [], pos = 3;

        function skipMatching(upto) {
            var depth = 0, start = pos;
            for (;;) {
                var next = text.charAt(pos);
                if (upto.test(next) && !depth) return text.slice(start, pos);
                if (/[{\[\(]/.test(next)) ++depth;
                else if (/[}\]\)]/.test(next)) --depth;
                ++pos;
            }
        }

        // Parse arguments
        if (text.charAt(pos) != ")") for (;;) {
            var name = text.slice(pos).match(/^([^, \(\[\{]+): /);
            if (name) {
                pos += name[0].length;
                name = name[1];
            }
            args.push({name: name, type: skipMatching(/[\),]/)});
            if (text.charAt(pos) == ")") break;
            pos += 2;
        }

        var rettype = text.slice(pos).match(/^\) -> (.*)$/);

        return {args: args, rettype: rettype && rettype[1]};
    }

    // Moving to the definition of something

    function jumpToDef(ts, cm) {
        function inner(varName) {
            var req = {type: "definition", variable: varName || null};
            var doc = findDoc(ts, cm.getDoc());
            ts.server.request(buildRequest(ts, doc, req), function(error, data) {
                if (error) return showError(ts, cm, error);
                if (!data.file && data.url) { Window.open(data.url); return; }

                if (data.file) {
                    var localDoc = ts.docs[data.file], found;
                    if (localDoc && (found = findContext(localDoc.doc, data))) {
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

        if (!atInterestingExpression(cm))
            dialog(cm, "Jump to variable", function(name) { if (name) inner(name); });
        else
            inner();
    }

    function jumpBack(ts, cm) {
        var pos = ts.jumpStack.pop(), doc = pos && ts.docs[pos.file];
        if (!doc) return;
        moveTo(ts, findDoc(ts, cm.getDoc()), doc, pos.start, pos.end);
    }

    function moveTo(ts, curDoc, doc, start, end) {
        doc.doc.setSelection(start, end);
        if (curDoc != doc && ts