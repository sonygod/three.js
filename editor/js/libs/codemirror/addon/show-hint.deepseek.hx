// CodeMirror, copyright (c) by Marijn Haverbeke and others
// Distributed under an MIT license: https://codemirror.net/LICENSE

// declare global: DOMRect

class ShowHint {
    static var HINT_ELEMENT_CLASS:String = "CodeMirror-hint";
    static var ACTIVE_HINT_ELEMENT_CLASS:String = "CodeMirror-hint-active";

    static function showHint(cm:CodeMirror, getHints:Dynamic, options:Dynamic):Void {
        if (!getHints) return cm.showHint(options);
        if (options && options.async) getHints.async = true;
        var newOpts = {hint: getHints};
        if (options) for (prop in options) newOpts[prop] = options[prop];
        return cm.showHint(newOpts);
    }

    static function defineExtension(cm:CodeMirror, options:Dynamic):Void {
        options = parseOptions(cm, cm.getCursor("start"), options);
        var selections = cm.listSelections();
        if (selections.length > 1) return;
        // By default, don't allow completion when something is selected.
        // A hint function can have a `supportsSelection` property to
        // indicate that it can handle selections.
        if (cm.somethingSelected()) {
            if (!options.hint.supportsSelection) return;
            // Don't try with cross-line selections
            for (var i = 0; i < selections.length; i++)
                if (selections[i].head.line != selections[i].anchor.line) return;
        }

        if (cm.state.completionActive) cm.state.completionActive.close();
        var completion = cm.state.completionActive = new Completion(cm, options);
        if (!completion.options.hint) return;

        CodeMirror.signal(cm, "startCompletion", cm);
        completion.update(true);
    }

    static function defineExtension(cm:CodeMirror):Void {
        if (cm.state.completionActive) cm.state.completionActive.close()
    }

    static function parseOptions(cm:CodeMirror, pos:Dynamic, options:Dynamic):Dynamic {
        var editor = cm.options.hintOptions;
        var out = {};
        for (prop in defaultOptions) out[prop] = defaultOptions[prop];
        if (editor) for (prop in editor)
            if (editor[prop] !== undefined) out[prop] = editor[prop];
        if (options) for (prop in options)
            if (options[prop] !== undefined) out[prop] = options[prop];
        if (out.hint.resolve) out.hint = out.hint.resolve(cm, pos)
        return out;
    }

    static function getText(completion:Dynamic):String {
        if (typeof completion == "string") return completion;
        else return completion.text;
    }

    static function buildKeyMap(completion:Dynamic, handle:Dynamic):Dynamic {
        var baseMap = {
            Up: function() {handle.moveFocus(-1);},
            Down: function() {handle.moveFocus(1);},
            PageUp: function() {handle.moveFocus(-handle.menuSize() + 1, true);},
            PageDown: function() {handle.moveFocus(handle.menuSize() - 1, true);},
            Home: function() {handle.setFocus(0);},
            End: function() {handle.setFocus(handle.length - 1);},
            Enter: handle.pick,
            Tab: handle.pick,
            Esc: handle.close
        };

        var mac = /Mac/.test(navigator.platform);

        if (mac) {
            baseMap["Ctrl-P"] = function() {handle.moveFocus(-1);};
            baseMap["Ctrl-N"] = function() {handle.moveFocus(1);};
        }

        var custom = completion.options.customKeys;
        var ourMap = custom ? {} : baseMap;
        function addBinding(key:String, val:Dynamic) {
            var bound;
            if (typeof val != "string")
                bound = function(cm) { return val(cm, handle); };
            // This mechanism is deprecated
            else if (baseMap.hasOwnProperty(val))
                bound = baseMap[val];
            else
                bound = val;
            ourMap[key] = bound;
        }
        if (custom)
            for (prop in custom) if (custom.hasOwnProperty(prop))
                addBinding(prop, custom[prop]);
        var extra = completion.options.extraKeys;
        if (extra)
            for (prop in extra) if (extra.hasOwnProperty(prop))
                addBinding(prop, extra[prop]);
        return ourMap;
    }

    static function getHintElement(hintsElement:Dynamic, el:Dynamic):Dynamic {
        while (el && el != hintsElement) {
            if (el.nodeName.toUpperCase() === "LI" && el.parentNode == hintsElement) return el;
            el = el.parentNode;
        }
    }

    static function Widget(completion:Dynamic, data:Dynamic):Void {
        this.id = "cm-complete-" + Math.floor(Math.random(1e6))
        this.completion = completion;
        this.data = data;
        this.picked = false;
        var widget = this, cm = completion.cm;
        var ownerDocument = cm.getInputField().ownerDocument;
        var parentWindow = ownerDocument.defaultView || ownerDocument.parentWindow;

        var hints = this.hints = ownerDocument.createElement("ul");
        hints.setAttribute("role", "listbox")
        hints.setAttribute("aria-expanded", "true")
        hints.id = this.id
        var theme = completion.cm.options.theme;
        hints.className = "CodeMirror-hints " + theme;
        this.selectedHint = data.selectedHint || 0;

        var completions = data.list;
        for (var i = 0; i < completions.length; ++i) {
            var elt = hints.appendChild(ownerDocument.createElement("li")), cur = completions[i];
            var className = HINT_ELEMENT_CLASS + (i != this.selectedHint ? "" : " " + ACTIVE_HINT_ELEMENT_CLASS);
            if (cur.className != null) className = cur.className + " " + className;
            elt.className = className;
            if (i == this.selectedHint) elt.setAttribute("aria-selected", "true")
            elt.id = this.id + "-" + i
            elt.setAttribute("role", "option")
            if (cur.render) cur.render(elt, data, cur);
            else elt.appendChild(ownerDocument.createTextNode(cur.displayText || getText(cur)));
            elt.hintId = i;
        }

        var container = completion.options.container || ownerDocument.body;
        var pos = cm.cursorCoords(completion.options.alignWithWord ? data.from : null);
        var left = pos.left, top = pos.bottom, below = true;
        var offsetLeft = 0, offsetTop = 0;
        if (container !== ownerDocument.body) {
            // We offset the cursor position because left and top are relative to the offsetParent's top left corner.
            var isContainerPositioned = ['absolute', 'relative', 'fixed'].indexOf(parentWindow.getComputedStyle(container).position) !== -1;
            var offsetParent = isContainerPositioned ? container : container.offsetParent;
            var offsetParentPosition = offsetParent.getBoundingClientRect();
            var bodyPosition = ownerDocument.body.getBoundingClientRect();
            offsetLeft = (offsetParentPosition.left - bodyPosition.left - offsetParent.scrollLeft);
            offsetTop = (offsetParentPosition.top - bodyPosition.top - offsetParent.scrollTop);
        }
        hints.style.left = (left - offsetLeft) + "px";
        hints.style.top = (top - offsetTop) + "px";

        // If we're at the edge of the screen, then we want the menu to appear on the left of the cursor.
        var winW = parentWindow.innerWidth || Math.max(ownerDocument.body.offsetWidth, ownerDocument.documentElement.offsetWidth);
        var winH = parentWindow.innerHeight || Math.max(ownerDocument.body.offsetHeight, ownerDocument.documentElement.offsetHeight);
        container.appendChild(hints);
        cm.getInputField().setAttribute("aria-autocomplete", "list")
        cm.getInputField().setAttribute("aria-owns", this.id)
        cm.getInputField().setAttribute("aria-activedescendant", this.id + "-" + this.selectedHint)

        var box = completion.options.moveOnOverlap ? hints.getBoundingClientRect() : new DOMRect();
        var scrolls = completion.options.paddingForScrollbar ? hints.scrollHeight > hints.clientHeight + 1 : false;

        // Compute in the timeout to avoid reflow on init
        var startScroll;
        setTimeout(function() {startScroll = cm.getScrollInfo();});

        var overlapY = box.bottom - winH;
        if (overlapY > 0) {
            var height = box.bottom - box.top, curTop = pos.top - (pos.bottom - box.top);
            if (curTop - height > 0) { // Fits above cursor
                hints.style.top = (top = pos.top - height - offsetTop) + "px";
                below = false;
            } else if (height > winH) {
                hints.style.height = (winH - 5) + "px";
                hints.style.top = (top = pos.bottom - box.top - offsetTop) + "px";
                var cursor = cm.getCursor();
                if (data.from.ch != cursor.ch) {
                    pos = cm.cursorCoords(cursor);
                    hints.style.left = (left = pos.left - offsetLeft) + "px";
                    box = hints.getBoundingClientRect();
                }
            }
        }
        var overlapX = box.right - winW;
        if (scrolls) overlapX += cm.display.nativeBarWidth;
        if (overlapX > 0) {
            if (box.right - box.left > winW) {
                hints.style.width = (winW - 5) + "px";
                overlapX -= (box.right - box.left) - winW;
            }
            hints.style.left = (left = pos.left - overlapX - offsetLeft) + "px";
        }
        if (scrolls) for (var node = hints.firstChild; node; node = node.nextSibling)
            node.style.paddingRight = cm.display.nativeBarWidth + "px"

        cm.addKeyMap(this.keyMap = buildKeyMap(completion, {
            moveFocus: function(n, avoidWrap) { widget.changeActive(widget.selectedHint + n, avoidWrap); },
            setFocus: function(n) { widget.changeActive(n); },
            menuSize: function() { return widget.screenAmount(); },
            length: completions.length,
            close: function() { completion.close(); },
            pick: function() { widget.pick(); },
            data: data
        }));

        if (completion.options.closeOnUnfocus) {
            var closingOnBlur;
            cm.on("blur", this.onBlur = function() { closingOnBlur = setTimeout(function() { completion.close(); }, 100); });
            cm.on("focus", this.onFocus = function() { clearTimeout(closingOnBlur); });
        }

        cm.on("scroll", this.onScroll = function() {
            var curScroll = cm.getScrollInfo(), editor = cm.getWrapperElement().getBoundingClientRect();
            if (!startScroll) startScroll = cm.getScrollInfo();
            var newTop = top + startScroll.top - curScroll.top;
            var point = newTop - (parentWindow.pageYOffset || (ownerDocument.documentElement || ownerDocument.body).scrollTop);
            if (!below) point += hints.offsetHeight;
            if (point <= editor.top || point >= editor.bottom) return completion.close();
            hints.style.top = newTop + "px";
            hints.style.left = (left + startScroll.left - curScroll.left) + "px";
        });

        CodeMirror.on(hints, "dblclick", function(e) {
            var t = getHintElement(hints, e.target || e.srcElement);
            if (t && t.hintId != null) {widget.changeActive(t.hintId); widget.pick();}
        });

        CodeMirror.on(hints, "click", function(e) {
            var t = getHintElement(hints, e.target || e.srcElement);
            if (t && t.hintId != null) {
                widget.changeActive(t.hintId);
                if (completion.options.completeOnSingleClick) widget.pick();
            }
        });

        CodeMirror.on(hints, "mousedown", function() {
            setTimeout(function(){cm.focus();}, 20);
        });

        // The first hint doesn't need to be scrolled to on init
        var selectedHintRange = this.getSelectedHintRange();
        if (selectedHintRange.from !== 0 || selectedHintRange.to !== 0) {
            this.scrollToActive();
        }

        CodeMirror.signal(data, "select", completions[this.selectedHint], hints.childNodes[this.selectedHint]);
        return true;
    }

    // ... 其他代码 ...
}