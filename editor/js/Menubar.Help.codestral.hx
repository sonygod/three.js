import js.Browser.window;
import js.html.HtmlElement;
import ui.UIPanel;
import ui.UIRow;

class MenubarHelp {
    private var container:UIPanel;
    private var options:UIPanel;
    private var editor:Editor;

    public function new(editor:Editor) {
        this.editor = editor;
        this.initialize();
    }

    private function initialize():Void {
        var strings = editor.strings;

        container = new UIPanel();
        container.setClass('menu');

        var title = new UIPanel();
        title.setClass('title');
        title.setTextContent(strings.getKey('menubar/help'));
        container.add(title);

        options = new UIPanel();
        options.setClass('options');
        container.add(options);

        addOption('menubar/help/source_code', 'https://github.com/mrdoob/three.js/tree/master/editor');
        addOption('menubar/help/about', 'https://threejs.org');
        addOption('menubar/help/manual', 'https://github.com/mrdoob/three.js/wiki/Editor-Manual');
    }

    private function addOption(key:String, url:String):Void {
        var option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey(key));
        option.onClick(function() {
            window.open(url, '_blank');
        });
        options.add(option);
    }

    public function getContainer():UIPanel {
        return container;
    }
}