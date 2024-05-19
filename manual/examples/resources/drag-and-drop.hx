package three.js.manual.examples.resources;

import js.Browser;
import js.html.DivElement;
import js.html.Document;
import js.html.Event;
import js.html.File;
import js.html.StyleElement;
import js.Lib;

class DragAndDrop {
    static var handlers = {
        onDropFile: function(file:File, index:Int) {}
    };

    static function setup(options:Dynamic) {
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

        var elem = Browser.document.createElement('div');
        elem.innerHTML = html;
        Browser.document.body.appendChild(elem);

        var dragInfo = cast Browser.document.querySelector('.dragInfo');
        function showDragInfo(show:Bool) {
            dragInfo.style.display = show ? '' : 'none';
        }

        Browser.document.body.addEventListener('dragenter', function(_) {
            showDragInfo(true);
        });

        var dragElem:DivElement = cast dragInfo;
        dragElem.addEventListener('dragover', function(e:Event) {
            e.preventDefault();
            return false;
        });

        dragElem.addEventListener('dragleave', function(_) {
            showDragInfo(false);
            return false;
        });

        dragElem.addEventListener('dragend', function(_) {
            showDragInfo(false);
            return false;
        });

        dragElem.addEventListener('drop', function(e:Event) {
            e.preventDefault();
            showDragInfo(false);
            if (e.dataTransfer.items) {
                var fileNdx:Int = 0;
                for (i in 0...e.dataTransfer.items.length) {
                    var item = e.dataTransfer.items[i];
                    if (item.kind == 'file') {
                        handlers.onDropFile(cast item.getAsFile(), fileNdx++);
                    }
                }
            }
            return false;
        });
    }

    static function onDropFile(fn:File->Int->Void) {
        handlers.onDropFile = fn;
    }
}