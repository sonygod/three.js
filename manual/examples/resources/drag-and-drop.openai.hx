package three.js.manual.examples.resources;

import js.html.DOMElement;
import js.html.Document;
import js.html.Event;
import js.html.File;
import js.Browser;

class DragAndDrop {

    private static var handlers = {
        onDropFile: function(file:File, index:Int) {}
    };

    public static function setup(options:{ msg:String }) {
        var html = '
            <style>
                .dragInfo {
                    position: fixed;
                    left: 0;
                    top: 0;
                    width: 100%;
                    height: 100%;
                    background: rgba(0, 0, 0, .9);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .dragInfo > div {
                    padding: 1em;
                    background: blue;
                    color: white;
                    pointer-events: none;
                }
                .dragerror div {
                    background: red !important;
                    font-weight: bold;
                    color: white;
                }
            </style>
            <div class="dragInfo" style="display: none;">
                <div>
                    ${options.msg}
                </div>
            </div>
        ';

        var elem:DOMElement = Browser.document.createElement("div");
        elem.innerHTML = html;
        Browser.document.body.appendChild(elem);

        var dragInfo:DOMElement = Browser.document.querySelector(".dragInfo");

        function showDragInfo(show:Bool) {
            dragInfo.style.display = show ? "" : "none";
        }

        Browser.document.body.addEventListener("dragenter", function(_) {
            showDragInfo(true);
        });

        var dragElem:DOMElement = dragInfo;

        dragElem.addEventListener("dragover", function(e:Event) {
            e.preventDefault();
            return false;
        });

        dragElem.addEventListener("dragleave", function(_) {
            showDragInfo(false);
            return false;
        });

        dragElem.addEventListener("dragend", function(_) {
            showDragInfo(false);
            return false;
        });

        dragElem.addEventListener("drop", function(e:Event) {
            e.preventDefault();
            showDragInfo(false);
            if (e.dataTransfer.items) {
                var fileNdx = 0;
                for (i in 0...e.dataTransfer.items.length) {
                    var item = e.dataTransfer.items[i];
                    if (item.kind == "file") {
                        handlers.onDropFile(item.getAsFile(), fileNdx++);
                    }
                }
            }
            return false;
        });
    }

    public static function onDropFile(fn:File->Int->Void) {
        handlers.onDropFile = fn;
    }
}