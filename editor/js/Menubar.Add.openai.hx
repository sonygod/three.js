package three.js.editor.js;

import three.js.Lib;

import ui.UIPanel;
import ui.UIRow;
import ui.UIHorizontalRule;

import commands.AddObjectCommand;

class MenubarAdd {
    private var editor:Dynamic;
    private var strings:Dynamic;

    public function new(editor:Dynamic) {
        strings = editor.strings;

        var container = new UIPanel();
        container.setClass('menu');

        var title = new UIPanel();
        title.setClass('title');
        title.setTextContent(strings.getKey('menubar/add'));
        container.add(title);

        var options = new UIPanel();
        options.setClass('options');
        container.add(options);

        // Group

        var option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/add/group'));
        option.onClick(function() {
            var mesh = new three.js.THREE.Group();
            mesh.name = 'Group';

            editor.execute(new AddObjectCommand(editor, mesh));
        });
        options.add(option);

        // Mesh

        var meshSubmenuTitle = new UIRow();
        meshSubmenuTitle.setTextContent(strings.getKey('menubar/add/mesh'));
        meshSubmenuTitle.addClass('option');
        meshSubmenuTitle.addClass('submenu-title');
        meshSubmenuTitle.onMouseOver(function() {
            var rect = meshSubmenuTitle.dom.getBoundingClientRect();
            var paddingTop = getComputedStyle(meshSubmenuTitle.dom).paddingTop;
            meshSubmenu.setLeft(rect.right + 'px');
            meshSubmenu.setTop(rect.top - Std.parseFloat(paddingTop) + 'px');
            meshSubmenu.setStyle('max-height', ['calc( 100vh - ${rect.top}px )']);
            meshSubmenu.setDisplay('block');
        });
        meshSubmenuTitle.onMouseOut(function() {
            meshSubmenu.setDisplay('none');
        });
        options.add(meshSubmenuTitle);

        var meshSubmenu = new UIPanel();
        meshSubmenu.setPosition('fixed');
        meshSubmenu.addClass('options');
        meshSubmenu.setDisplay('none');
        meshSubmenuTitle.add(meshSubmenu);

        // Mesh / Box

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/add/mesh/box'));
        option.onClick(function() {
            var geometry = new three.js.THREE.BoxGeometry(1, 1, 1, 1, 1, 1);
            var mesh = new three.js.THREE.Mesh(geometry, new three.js.THREE.MeshStandardMaterial());
            mesh.name = 'Box';

            editor.execute(new AddObjectCommand(editor, mesh));
        });
        meshSubmenu.add(option);

        // ... (rest of the menu items)

        // Light

        var lightSubmenuTitle = new UIRow();
        lightSubmenuTitle.setTextContent(strings.getKey('menubar/add/light'));
        lightSubmenuTitle.addClass('option');
        lightSubmenuTitle.addClass('submenu-title');
        lightSubmenuTitle.onMouseOver(function() {
            var rect = lightSubmenuTitle.dom.getBoundingClientRect();
            var paddingTop = getComputedStyle(lightSubmenuTitle.dom).paddingTop;
            lightSubmenu.setLeft(rect.right + 'px');
            lightSubmenu.setTop(rect.top - Std.parseFloat(paddingTop) + 'px');
            lightSubmenu.setStyle('max-height', ['calc( 100vh - ${rect.top}px )']);
            lightSubmenu.setDisplay('block');
        });
        lightSubmenuTitle.onMouseOut(function() {
            lightSubmenu.setDisplay('none');
        });
        options.add(lightSubmenuTitle);

        var lightSubmenu = new UIPanel();
        lightSubmenu.setPosition('fixed');
        lightSubmenu.addClass('options');
        lightSubmenu.setDisplay('none');
        lightSubmenuTitle.add(lightSubmenu);

        // ... (rest of the menu items)

        // Camera

        var cameraSubmenuTitle = new UIRow();
        cameraSubmenuTitle.setTextContent(strings.getKey('menubar/add/camera'));
        cameraSubmenuTitle.addClass('option');
        cameraSubmenuTitle.addClass('submenu-title');
        cameraSubmenuTitle.onMouseOver(function() {
            var rect = cameraSubmenuTitle.dom.getBoundingClientRect();
            var paddingTop = getComputedStyle(cameraSubmenuTitle.dom).paddingTop;
            cameraSubmenu.setLeft(rect.right + 'px');
            cameraSubmenu.setTop(rect.top - Std.parseFloat(paddingTop) + 'px');
            cameraSubmenu.setStyle('max-height', ['calc( 100vh - ${rect.top}px )']);
            cameraSubmenu.setDisplay('block');
        });
        cameraSubmenuTitle.onMouseOut(function() {
            cameraSubmenu.setDisplay('none');
        });
        options.add(cameraSubmenuTitle);

        var cameraSubmenu = new UIPanel();
        cameraSubmenu.setPosition('fixed');
        cameraSubmenu.addClass('options');
        cameraSubmenu.setDisplay('none');
        cameraSubmenuTitle.add(cameraSubmenu);

        // ... (rest of the menu items)

        return container;
    }
}