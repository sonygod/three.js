package three.js.editor.js;

import ui UIPanel;
import ui.UIRow;
import ui.UIHorizontalRule;
import Loader;

class MenubarFile {
    public function new(editor:Editor) {
        var strings = editor.strings;
        var saveArrayBuffer = editor.utils.saveArrayBuffer;
        var saveString = editor.utils.saveString;

        var container = new UIPanel();
        container.setClass('menu');

        var title = new UIPanel();
        title.setClass('title');
        title.setTextContent(strings.getKey('menubar/file'));
        container.add(title);

        var options = new UIPanel();
        options.setClass('options');
        container.add(options);

        // New Project

        var newProjectSubmenuTitle = new UIRow();
        newProjectSubmenuTitle.setTextContent(strings.getKey('menubar/file/newProject')).addClass('option').addClass('submenu-title');
        newProjectSubmenuTitle.onMouseOver(function() {
            var top = newProjectSubmenuTitle.dom.getBoundingClientRect().top;
            var right = newProjectSubmenuTitle.dom.getBoundingClientRect().right;
            var paddingTop = Std.parseFloat(getComputedStyle(newProjectSubmenuTitle.dom).paddingTop);
            newProjectSubmenu.setLeft(right + 'px');
            newProjectSubmenu.setTop(top - paddingTop + 'px');
            newProjectSubmenu.setDisplay('block');
        });
        newProjectSubmenuTitle.onMouseOut(function() {
            newProjectSubmenu.setDisplay('none');
        });
        options.add(newProjectSubmenuTitle);

        var newProjectSubmenu = new UIPanel().setPosition('fixed').addClass('options').setDisplay('none');
        newProjectSubmenuTitle.add(newProjectSubmenu);

        // ... (rest of the code remains the same)

        return container;
    }
}