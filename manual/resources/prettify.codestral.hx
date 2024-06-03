import js.html.Node;
import js.html.DOM;
import js.html.Element;

class Main {
    static function main() {
        var win = js.Browser.window;
        var document = js.Browser.document;

        var prettyPrintOne: js.Function = function(sourceCodeHtml: String, opt_langExtension: String, opt_numberLines: js.Dynamic) {
            var container: Element = document.createElement("div");
            container.innerHTML = "<pre>" + sourceCodeHtml + "</pre>";
            container = container.firstChild;

            if (opt_numberLines) {
                numberLines(container, opt_numberLines, true);
            }

            var job = {
                langExtension: opt_langExtension,
                numberLines: opt_numberLines,
                sourceNode: container,
                pre: 1
            };
            applyDecorator(job);
            return container.innerHTML;
        };

        var prettyPrint: js.Function = function(opt_whenDone: js.Function, opt_root: Element) {
            var root: Element = opt_root || document.body;
            var doc: Document = root.ownerDocument || document;

            function byTagName(tn: String): Array<Element> {
                return root.getElementsByTagName(tn);
            }

            var codeSegments: Array<Array<Element>> = [byTagName("pre"), byTagName("code"), byTagName("xmp")];
            var elements: Array<Element> = [];

            for (var i: Int = 0; i < codeSegments.length; ++i) {
                for (var j: Int = 0, n: Int = codeSegments[i].length; j < n; ++j) {
                    elements.push(codeSegments[i][j]);
                }
            }
            codeSegments = null;

            var k: Int = 0;
            var prettyPrintingJob: js.Dynamic;

            var langExtensionRe: RegExp = new EReg("\\blang(?:uage)?-([\\w.]+)(?!\\S)", "");
            var prettyPrintRe: RegExp = new EReg("\\bprettyprint\\b", "");
            var prettyPrintedRe: RegExp = new EReg("\\bprettyprinted\\b", "");
            var preformattedTagNameRe: RegExp = new EReg("pre|xmp", "i");
            var codeRe: RegExp = new EReg("^code$", "i");
            var preCodeXmpRe: RegExp = new EReg("^(?:pre|code|xmp)$", "i");
            var EMPTY: js.Dynamic = {};

            function doWork() {
                var endTime: Float = (js.Browser.window["PR_SHOULD_USE_CONTINUATION"] ? js.Browser.window.performance.now() + 250 : Infinity);

                for (; k < elements.length && js.Browser.window.performance.now() < endTime; k++) {
                    var cs: Element = elements[k];
                    var attrs: js.Dynamic = EMPTY;

                    for (var preceder: Node = cs; (preceder = preceder.previousSibling);) {
                        var nt: Int = preceder.nodeType;
                        var value: String = (nt == 7 || nt == 8) && preceder.nodeValue;

                        if (value ? !/^\??prettify\b/.test(value) : (nt !== 3 || /\S/.test(preceder.nodeValue))) {
                            break;
                        }

                        if (value) {
                            attrs = {};
                            value.replace(new EReg("\\b(\\w+)=([\\w:.%+-]+)", "g"), function(_, name: String, value: String) {
                                attrs[name] = value;
                                return "";
                            });
                            break;
                        }
                    }

                    var className: String = cs.className;

                    if ((attrs !== EMPTY || prettyPrintRe.test(className)) && !prettyPrintedRe.test(className)) {
                        var nested: Bool = false;

                        for (var p: Element = cs.parentNode; p; p = p.parentNode) {
                            var tn: String = p.tagName;

                            if (preCodeXmpRe.test(tn) && p.className && prettyPrintRe.test(p.className)) {
                                nested = true;
                                break;
                            }
                        }

                        if (!nested) {
                            cs.className += " prettyprinted";

                            var langExtension: String = attrs["lang"];

                            if (!langExtension) {
                                langExtension = className.match(langExtensionRe);
                                var wrapper: Element;

                                if (!langExtension && (wrapper = childContentWrapper(cs)) && codeRe.test(wrapper.tagName)) {
                                    langExtension = wrapper.className.match(langExtensionRe);
                                }

                                if (langExtension) {
                                    langExtension = langExtension[1];
                                }
                            }

                            var preformatted: Int;

                            if (preformattedTagNameRe.test(cs.tagName)) {
                                preformatted = 1;
                            } else {
                                var currentStyle: String = cs["currentStyle"];
                                var defaultView: Document = doc.defaultView;
                                var whitespace: String = (currentStyle ? currentStyle["whiteSpace"] : (defaultView && defaultView.getComputedStyle) ? defaultView.getComputedStyle(cs, null).getPropertyValue("white-space") : "");
                                preformatted = whitespace && "pre" === whitespace.substring(0, 3) ? 1 : 0;
                            }

                            var lineNums: js.Dynamic = attrs["linenums"];

                            if (!(lineNums = lineNums === "true" || js.Dynamic.parseFloat(lineNums))) {
                                lineNums = className.match(new EReg("\\blinenums\\b(?::(\\d+))?", ""));
                                lineNums = lineNums ? lineNums[1] && lineNums[1].length ? Std.parseInt(lineNums[1]) : true : false;
                            }

                            var showLineMods: Bool = attrs["showlinemods"];

                            if (showLineMods === null) {
                                showLineMods = className.match(new EReg("\\bshowlinemods\\b", "")) !== null;
                            }

                            if (lineNums || showLineMods) {
                                numberLines(cs, lineNums, preformatted == 1, lineNums, showLineMods);
                            }

                            prettyPrintingJob = {
                                langExtension: langExtension,
                                sourceNode: cs,
                                numberLines: lineNums,
                                pre: preformatted
                            };
                            applyDecorator(prettyPrintingJob);
                        }
                    }
                }

                if (k < elements.length) {
                    js.Browser.window.setTimeout(doWork, 250);
                } else if (js.Browser.window.js.Type.isFunction(opt_whenDone)) {
                    opt_whenDone();
                }
            }

            doWork();
        };

        win["prettyPrintOne"] = prettyPrintOne;
        win["prettyPrint"] = prettyPrint;
    }

    static function childContentWrapper(element: Element): Element {
        var wrapper: Element = null;

        for (var c: Node = element.firstChild; c; c = c.nextSibling) {
            var type: Int = c.nodeType;
            wrapper = (type === 1) ? (wrapper ? element : c) : (type === 3) ? (c.nodeValue.trim() !== "" ? element : wrapper) : wrapper;
        }

        return wrapper === element ? null : wrapper;
    }

    static function numberLines(node: Element, opt_startLineNum: js.Dynamic, isPreformatted: Bool, opt_numberLines: js.Dynamic, opt_calloutModifiedLines: Bool) {
        // Implementation of numberLines function here...
    }

    static function applyDecorator(job: js.Dynamic) {
        // Implementation of applyDecorator function here...
    }
}