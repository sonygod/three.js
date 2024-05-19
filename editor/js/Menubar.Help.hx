package three.js.editor.js;

import js.html.Window;
import js.html.AnchorElement;
import ui.UIPanel;
import ui.UIRow;

class MenubarHelp {
    private var editor:Dynamic;
    private var strings:Dynamic;

    public function new(editor:Dynamic) {
        this.editor = editor;
        this.strings = editor.strings;

        var container = new UIPanel();
        container.setClass('menu');

        var title = new UIPanel();
        title.setClass('title');
        title.setTextContent(strings.getKey('menubar/help'));
        container.add(title);

        var options = new UIPanel();
        options.setClass('options');
        container.add(options);

        // Source code

        var option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/help/source_code'));
        option.onClick(function(_) {
            js.Browser.window.open('https://github.com/mrdoob/three.js/tree/master/editor', '_blank');
        });
        options.add(option);

        /*
        // Icon

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/help/icons'));
        option.onClick(function(_) {
            js.Browser.window.open('https://www.flaticon.com/packs/interface-44', '_blank');
        });
        options.add(option);
        */

        // About

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/help/about'));
        option.onClick(function(_) {
            js.Browser.window.open('https://threejs.org', '_blank');
        });
        options.add(option);

        // Manual

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/help/manual'));
        option.onClick(function(_) {
            js.Browser.window.open('https://github.com/mrdoob/three.js/wiki/Editor-Manual', '_blank');
        });
        options.add(option);

        return container;
    }

    public static function main(editor:Dynamic) {
        return new MenubarHelp(editor);
    }
}