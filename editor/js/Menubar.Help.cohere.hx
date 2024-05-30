import js.Browser.window;

class MenubarHelp {
    public function new(editor:Editor) {
        var container = UIPanel.create();
        container.setClass('menu');

        var title = UIPanel.create();
        title.setClass('title');
        title.setTextContent(editor.strings.getKey('menubar/help'));
        container.add(title);

        var options = UIPanel.create();
        options.setClass('options');
        container.add(options);

        // Source code
        var option = UIRow.create();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/help/source_code'));
        option.onClick(function() {
            window.open('https://github.com/mrdoob/three.js/tree/master/editor', '_blank');
        });
        options.add(option);

        // About
        option = UIRow.create();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/help/about'));
        option.onClick(function() {
            window.open('https://threejs.org', '_blank');
        });
        options.add(option);

        // Manual
        option = UIRow.create();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/help/manual'));
        option.onClick(function() {
            window.open('https://github.com/mrdoob/three.js/wiki/Editor-Manual', '_blank');
        });
        options.add(option);

        return container;
    }
}

class UIPanel {
    public static function create():UIPanel;
}

class UIRow {
    public static function create():UIRow;
    public function setClass(className:String):Void;
    public function setTextContent(text:String):Void;
    public function onClick(callback:Void->Void):Void;
}