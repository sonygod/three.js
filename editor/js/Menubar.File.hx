package three.js.editor.js;

import ui.UIPanel;
import ui.UIRow;
import ui.UIHorizontalRule;
import loader.Loader;

class MenubarFile {
    private var editor:Editor;

    public function new(editor:Editor) {
        this.editor = editor;

        var strings = editor.strings;

        var saveArrayBuffer = editor.utils.saveArrayBuffer;
        var saveString = editor.utils.saveString;

        var container = new UIPanel();
        container.addClass('menu');

        var title = new UIPanel();
        title.addClass('title');
        title.setTextContent(strings.getKey('menubar/file'));
        container.add(title);

        var options = new UIPanel();
        options.addClass('options');
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

        // New Project / Empty

        var option = new UIRow();
        option.setTextContent(strings.getKey('menubar/file/newProject/empty')).setClass('option');
        option.onClick(function() {
            if (confirm(strings.getKey('prompt/file/open'))) {
                editor.clear();
            }
        });
        newProjectSubmenu.add(option);

        // ...

        // Save

        option = new UIRow();
        option.addClass('option');
        option.setTextContent(strings.getKey('menubar/file/save'));
        option.onClick(function() {
            var json = editor.toJSON();
            var blob = new Blob([Json.stringify(json)], { type: 'application/json' });
            editor.utils.save(blob, 'project.json');
        });
        options.add(option);

        // Open

        var openProjectForm = js.Browser.document.createFormElement();
        openProjectForm.style.display = 'none';
        js.Browser.document.body.appendChild(openProjectForm);

        var openProjectInput = js.Browser.document.createInputElement('file');
        openProjectInput.multiple = false;
        openProjectInput.type = 'file';
        openProjectInput.accept = '.json';
        openProjectInput.addEventListener('change', async function() {
            var file = openProjectInput.files[0];
            if (file === null) return;
            try {
                var json = Json.parse(await file.text());
                async function onEditorCleared() {
                    await editor.fromJSON(json);
                    editor.signals.editorCleared.remove(onEditorCleared);
                }
                editor.signals.editorCleared.add(onEditorCleared);
                editor.clear();
            } catch (e) {
                alert(strings.getKey('prompt/file/failedToOpenProject'));
                console.error(e);
            } finally {
                openProjectForm.reset();
            }
        });
        openProjectForm.appendChild(openProjectInput);

        option = new UIRow();
        option.addClass('option');
        option.setTextContent(strings.getKey('menubar/file/open'));
        option.onClick(function() {
            if (confirm(strings.getKey('prompt/file/open'))) {
                openProjectInput.click();
            }
        });
        options.add(option);

        // ...

        // Export

        var fileExportSubmenuTitle = new UIRow();
        fileExportSubmenuTitle.setTextContent(strings.getKey('menubar/file/export')).addClass('option').addClass('submenu-title');
        fileExportSubmenuTitle.onMouseOver(function() {
            var top = fileExportSubmenuTitle.dom.getBoundingClientRect().top;
            var right = fileExportSubmenuTitle.dom.getBoundingClientRect().right;
            var paddingTop = Std.parseFloat(getComputedStyle(fileExportSubmenuTitle.dom).paddingTop);
            fileExportSubmenu.setLeft(right + 'px');
            fileExportSubmenu.setTop(top - paddingTop + 'px');
            fileExportSubmenu.setDisplay('block');
        });
        fileExportSubmenuTitle.onMouseOut(function() {
            fileExportSubmenu.setDisplay('none');
        });
        options.add(fileExportSubmenuTitle);

        var fileExportSubmenu = new UIPanel().setPosition('fixed').addClass('options').setDisplay('none');
        fileExportSubmenuTitle.add(fileExportSubmenu);

        // Export DRC

        option = new UIRow();
        option.addClass('option');
        option.setTextContent('DRC');
        option.onClick(async function() {
            var object = editor.selected;
            if (object === null || object.isMesh === undefined) {
                alert(strings.getKey('prompt/file/export/noMeshSelected'));
                return;
            }
            var dracoExporter = await Loader.load('three/addons/exporters/DRACOExporter.js');
            var exporter = new dracoExporter.DRACOExporter();
            var options = {
                decodeSpeed: 5,
                encodeSpeed: 5,
                encoderMethod: dracoExporter.DRACOExporter.MESH_EDGEBREAKER_ENCODING,
                quantization: [16, 8, 8, 8, 8],
                exportUvs: true,
                exportNormals: true,
                exportColor: object.geometry.hasAttribute('color')
            };
            var result = exporter.parse(object, options);
            saveArrayBuffer(result, 'model.drc');
        });
        fileExportSubmenu.add(option);

        // ...

        return container;
    }
}