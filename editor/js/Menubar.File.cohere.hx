package;

import js.Browser.window;
import js.html.Document;
import js.html.Form;
import js.html.Input;
import js.html.Node;

class MenubarFile {
    static function new(editor:Editor) {
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
        newProjectSubmenuTitle.setTextContent(strings.getKey('menubar/file/newProject'));
        newProjectSubmenuTitle.addClass('option');
        newProjectSubmenuTitle.addClass('submenu-title');
        newProjectSubmenuTitle.onMouseOver(function() {
            var rect = newProjectSubmenuTitle.dom.getBoundingClientRect();
            var paddingTop = newProjectSubmenuTitle.dom.style.paddingTop;
            newProjectSubmenu.setLeft(Std.string(rect.right) + 'px');
            newProjectSubmenu.setTop(Std.string(rect.top - Std.parseFloat(paddingTop)) + 'px');
            newProjectSubmenu.setDisplay('block');
        });
        newProjectSubmenuTitle.onMouseOut(function() {
            newProjectSubmenu.setDisplay('none');
        });
        options.add(newProjectSubmenuTitle);

        var newProjectSubmenu = new UIPanel();
        newProjectSubmenu.setPosition('fixed');
        newProjectSubmenu.addClass('options');
        newProjectSubmenu.setDisplay('none');
        newProjectSubmenuTitle.add(newProjectSubmenu);

        // New Project / Empty

        var option = new UIRow();
        option.setTextContent(strings.getKey('menubar/file/newProject/empty'));
        option.setClass('option');
        option.onClick(function() {
            if (window.confirm(strings.getKey('prompt/file/open'))) {
                editor.clear();
            }
        });
        newProjectSubmenu.add(option);

        //

        newProjectSubmenu.add(new UIHorizontalRule());

        // New Project / ...

        var examples = [
            { title: 'menubar/file/newProject/Arkanoid', file: 'arkanoid.app.json' },
            { title: 'menubar/file/newProject/Camera', file: 'camera.app.json' },
            { title: 'menubar/file/newProject/Particles', file: 'particles.app.json' },
            { title: 'menubar/file/newProject/Pong', file: 'pong.app.json' },
            { title: 'menubar/file/newProject/Shaders', file: 'shaders.app.json' }
        ];

        var loader = new js.three.FileLoader();

        for (i in 0...examples.length) {
            var example = examples[i];
            var option = new UIRow();
            option.setClass('option');
            option.setTextContent(strings.getKey(example.title));
            option.onClick(function() {
                if (window.confirm(strings.getKey('prompt/file/open'))) {
                    loader.load('examples/' + example.file, function(text) {
                        editor.clear();
                        editor.fromJSON(JSON.parse(text));
                    });
                }
            });
            newProjectSubmenu.add(option);
        }

        // Save

        option = new UIRow();
        option.addClass('option');
        option.setTextContent(strings.getKey('menubar/file/save'));
        option.onClick(function() {
            var json = editor.toJSON();
            var blob = new js.Blob([JSON.stringify(json)], { type: 'application/json' });
            editor.utils.save(blob, 'project.json');
        });
        options.add(option);

        // Open

        var openProjectForm = cast Document(window.document).createElement('form');
        openProjectForm.style.display = 'none';
        cast Document(window.document).body.appendChild(openProjectForm);

        var openProjectInput = cast Document(window.document).createElement('input');
        openProjectInput.multiple = false;
        openProjectInput.type = 'file';
        openProjectInput.accept = '.json';
        openProjectInput.addEventListener('change', function() {
            var file = openProjectInput.files[0];
            if (file == null) return;
            try {
                var json = JSON.parse(file.text());
                editor.signals.editorCleared.add(function() {
                    editor.fromJSON(json);
                    editor.signals.editorCleared.remove();
                });
                editor.clear();
            } catch (e) {
                window.alert(strings.getKey('prompt/file/failedToOpenProject'));
                trace(e);
            } finally {
                openProjectForm.reset();
            }
        });
        openProjectForm.appendChild(openProjectInput);

        option = new UIRow();
        option.addClass('option');
        option.setTextContent(strings.getKey('menubar/file/open'));
        option.onClick(function() {
            if (window.confirm(strings.getKey('prompt/file/open'))) {
                openProjectInput.click();
            }
        });
        options.add(option);

        //

        options.add(new UIHorizontalRule());

        // Import

        var form = cast Document(window.document).createElement('form');
        form.style.display = 'none';
        cast Document(window.document).body.appendChild(form);

        var fileInput = cast Document(window.document).createElement('input');
        fileInput.multiple = true;
        fileInput.type = 'file';
        fileInput.addEventListener('change', function() {
            editor.loader.loadFiles(fileInput.files);
            form.reset();
        });
        form.appendChild(fileInput);

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/file/import'));
        option.onClick(function() {
            fileInput.click();
        });
        options.add(option);

        // Export

        var fileExportSubmenuTitle = new UIRow();
        fileExportSubmenuTitle.setTextContent(strings.getKey('menubar/file/export'));
        fileExportSubmenuTitle.addClass('option');
        fileExportSubmenuTitle.addClass('submenu-title');
        fileExportSubmenuTitle.onMouseOver(function() {
            var rect = fileExportSubmenuTitle.dom.getBoundingClientRect();
            var paddingTop = fileExportSubmenuTitle.dom.style.paddingTop;
            fileExportSubmenu.setLeft(Std.string(rect.right) + 'px');
            fileExportSubmenu.setTop(Std.string(rect.top - Std.parseFloat(paddingTop)) + 'px');
            fileExportSubmenu.setDisplay('block');
        });
        fileExportSubmenuTitle.onMouseOut(function() {
            fileExportSubmenu.setDisplay('none');
        });
        options.add(fileExportSubmenuTitle);

        var fileExportSubmenu = new UIPanel();
        fileExportSubmenu.setPosition('fixed');
        fileExportSubmenu.addClass('options');
        fileExportSubmenu.setDisplay('none');
        fileExportSubmenuTitle.add(fileExportSubmenu);

        // Export DRC

        option = new UIRow();
        option.setClass('option');
        option.setTextContent('DRC');
        option.onClick(function() {
            var object = editor.selected;
            if (object == null || !Reflect.hasField(object, 'isMesh')) {
                window.alert(strings.getKey('prompt/file/export/noMeshSelected'));
                return;
            }
            var DRACOExporter = js.three.DRACOExporter.instance;
            var exporter = new DRACOExporter();
            var options = {
                decodeSpeed: 5,
                encodeSpeed: 5,
                encoderMethod: DRACOExporter.MESH_EDGEBREAKER_ENCODING,
                quantization: [16, 8, 8, 8, 8],
                exportUvs: true,
                exportNormals: true,
                exportColor: Reflect.hasField(object.geometry, 'hasAttribute') && object.geometry.hasAttribute('color')
            };
            saveArrayBuffer(exporter.parse(object, options), 'model.drc');
        });
        fileExportSubmenu.add(option);

        // Export GLB

        option = new UIRow();
        option.setClass('option');
        option.setTextContent('GLB');
        option.onClick(function() {
            var scene = editor.scene;
            var animations = getAnimations(scene);
            var optimizedAnimations = [];
            for (animation in animations) {
                optimizedAnimations.push(animation.clone().optimize());
            }
            var GLTFExporter = js.three.GLTFExporter.instance;
            var exporter = new GLTFExporter();
            exporter.parse(scene, function(result) {
                saveArrayBuffer(result, 'scene.glb');
            }, null, { binary: true, animations: optimizedAnimations });
        });
        fileExportSubmenu.add(option);

        // Export GLTF

        option = new UIRow();
        option.setClass('option');
        option.setTextContent('GLTF');
        option.onClick(function() {
            var scene = editor.scene;
            var animations = getAnimations(scene);
            var optimizedAnimations = [];
            for (animation in animations) {
                optimizedAnimations.push(animation.clone().optimize());
            }
            var GLTFExporter = js.three.GLTFExporter.instance;
            var exporter = new GLTFExporter();
            exporter.parse(scene, function(result) {
                saveString(JSON.stringify(result, null, 2), 'scene.gltf');
            }, null, { animations: optimizedAnimations });
        });
        fileExportSubmenu.add(option);

        // Export OBJ

        option = new UIRow();
        option.setClass('option');
        option.setTextContent('OBJ');
        option.onClick(function() {
            var object = editor.selected;
            if (object == null) {
                window.alert(strings.getKey('prompt/file/export/noObjectSelected'));
                return;
            }
            var OBJExporter = js.three.OBJExporter.instance;
            saveString(OBJExporter.parse(object), 'model.obj');
        });
        fileExportSubmenu.add(option);

        // Export PLY (ASCII)

        option = new UIRow();
        option.setClass('option');
        option.setTextContent('PLY');
        option.onClick(function() {
            var PLYExporter = js.three.PLYExporter.instance;
            PLYExporter.parse(editor.scene, function(result) {
                saveArrayBuffer(result, 'model.ply');
            });
        });
        fileExportSubmenu.add(option);

        // Export PLY (BINARY)

        option = new UIRow();
        option.setClass('option');
        option.setTextContent('PLY (BINARY)');
        option.onClick(function() {
            var PLYExporter = js.three.PLYExporter.instance;
            PLYExporter.parse(editor.scene, function(result) {
                saveArrayBuffer(result, 'model-binary.ply');
            }, { binary: true });
        });
        fileExportSubmenu.add(option);

        // Export STL (ASCII)

        option = new UIRow();
        option.setClass('option');
        option.setTextContent('STL');
        option.onClick(function() {
            var STLExporter = js.three.STLExporter.instance;
            saveString(STLExporter.parse(editor.scene), 'model.stl');
        });
        fileExportSubmenu.add(option);

        // Export STL (BINARY)

        option = new UIRow();
        option.setClass('option');
        option.setTextContent('STL (BINARY)');
        option.onClick(function() {
            var STLExporter = js.three.STLExporter.instance;
            saveArrayBuffer(STLExporter.parse(editor.scene, { binary: true }), 'model-binary.stl');
        });
        fileExportSubmenu.add(option);

        // Export USDZ

        option = new UIRow();
        option.setClass('option');
        option.setTextContent('USDZ');
        option.onClick(function() {
            var USDZExporter = js.three.USDZExporter.instance;
            saveArrayBuffer(USDZExporter.parseAsync(editor.scene), 'model.usdz');
        });
        fileExportSubmenu.add(option);

        //

        function getAnimations(scene) {
            var animations = [];
            scene.traverse(function(object) {
                animations.pushArray(object.animations);
            });
            return animations;
        }

        return container;
    }
}