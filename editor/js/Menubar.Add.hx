package three.js.editor.js;

import three.js.Three;

import ui.UIPanel;
import ui.UIRow;
import ui.UIHorizontalRule;

import commands.AddObjectCommand;

class MenubarAdd {
    public function new(editor:Editor) {
        var strings = editor.strings;

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
            var mesh = new THREE.Group();
            mesh.name = 'Group';

            editor.execute(new AddObjectCommand(editor, mesh));
        });
        options.add(option);

        // Mesh

        var meshSubmenuTitle = new UIRow();
        meshSubmenuTitle.setTextContent(strings.getKey('menubar/add/mesh')).addClass('option').addClass('submenu-title');
        meshSubmenuTitle.onMouseOver(function() {
            var domRect = meshSubmenuTitle.dom.getBoundingClientRect();
            var paddingTop = getComputedStyle(meshSubmenuTitle.dom).paddingTop;
            meshSubmenu.setLeft(domRect.right + 'px');
            meshSubmenu.setTop(domRect.top - Std.parseFloat(paddingTop) + 'px');
            meshSubmenu.setStyle('max-height', ['calc(100vh - ' + domRect.top + 'px)']);
            meshSubmenu.setDisplay('block');
        });
        meshSubmenuTitle.onMouseOut(function() {
            meshSubmenu.setDisplay('none');
        });
        options.add(meshSubmenuTitle);

        var meshSubmenu = new UIPanel().setPosition('fixed').addClass('options').setDisplay('none');
        meshSubmenuTitle.add(meshSubmenu);

        // Mesh / Box

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/add/mesh/box'));
        option.onClick(function() {
            var geometry = new THREE.BoxGeometry(1, 1, 1, 1, 1, 1);
            var mesh = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial());
            mesh.name = 'Box';

            editor.execute(new AddObjectCommand(editor, mesh));
        });
        meshSubmenu.add(option);

        // ... (rest of the mesh options)

        // Light

        var lightSubmenuTitle = new UIRow();
        lightSubmenuTitle.setTextContent(strings.getKey('menubar/add/light')).addClass('option').addClass('submenu-title');
        lightSubmenuTitle.onMouseOver(function() {
            var domRect = lightSubmenuTitle.dom.getBoundingClientRect();
            var paddingTop = getComputedStyle(lightSubmenuTitle.dom).paddingTop;
            lightSubmenu.setLeft(domRect.right + 'px');
            lightSubmenu.setTop(domRect.top - Std.parseFloat(paddingTop) + 'px');
            lightSubmenu.setStyle('max-height', ['calc(100vh - ' + domRect.top + 'px)']);
            lightSubmenu.setDisplay('block');
        });
        lightSubmenuTitle.onMouseOut(function() {
            lightSubmenu.setDisplay('none');
        });
        options.add(lightSubmenuTitle);

        var lightSubmenu = new UIPanel().setPosition('fixed').addClass('options').setDisplay('none');
        lightSubmenuTitle.add(lightSubmenu);

        // Light / Ambient

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/add/light/ambient'));
        option.onClick(function() {
            var color = 0x222222;

            var light = new THREE.AmbientLight(color);
            light.name = 'AmbientLight';

            editor.execute(new AddObjectCommand(editor, light));
        });
        lightSubmenu.add(option);

        // ... (rest of the light options)

        // Camera

        var cameraSubmenuTitle = new UIRow();
        cameraSubmenuTitle.setTextContent(strings.getKey('menubar/add/camera')).addClass('option').addClass('submenu-title');
        cameraSubmenuTitle.onMouseOver(function() {
            var domRect = cameraSubmenuTitle.dom.getBoundingClientRect();
            var paddingTop = getComputedStyle(cameraSubmenuTitle.dom).paddingTop;
            cameraSubmenu.setLeft(domRect.right + 'px');
            cameraSubmenu.setTop(domRect.top - Std.parseFloat(paddingTop) + 'px');
            cameraSubmenu.setStyle('max-height', ['calc(100vh - ' + domRect.top + 'px)']);
            cameraSubmenu.setDisplay('block');
        });
        cameraSubmenuTitle.onMouseOut(function() {
            cameraSubmenu.setDisplay('none');
        });
        options.add(cameraSubmenuTitle);

        var cameraSubmenu = new UIPanel().setPosition('fixed').addClass('options').setDisplay('none');
        cameraSubmenuTitle.add(cameraSubmenu);

        // Camera / Orthographic

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/add/camera/orthographic'));
        option.onClick(function() {
            var aspect = editor.camera.aspect;
            var camera = new THREE.OrthographicCamera(-aspect, aspect);
            camera.name = 'OrthographicCamera';

            editor.execute(new AddObjectCommand(editor, camera));
        });
        cameraSubmenu.add(option);

        // Camera / Perspective

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/add/camera/perspective'));
        option.onClick(function() {
            var camera = new THREE.PerspectiveCamera();
            camera.name = 'PerspectiveCamera';

            editor.execute(new AddObjectCommand(editor, camera));
        });
        cameraSubmenu.add(option);

        return container;
    }
}