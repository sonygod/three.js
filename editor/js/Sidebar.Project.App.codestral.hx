extern class THREE {
    public function new();
    public static function LoadingManager(onLoad:Dynamic->Void):Void;
    public static class FileLoader {
        public function new(manager:THREE.LoadingManager);
        public function load(url:String, onLoad:String->Void):Void;
    }
}

extern class zipSync {
    public function new(toZip:Dynamic, options:Dynamic):Dynamic;
}

extern class strToU8 {
    public function new(str:String):Uint8Array;
}

extern class UIButton {
    public function new(label:String);
    public function setWidth(width:String):UIButton;
    public function setMarginLeft(margin:String):UIButton;
    public function setMarginBottom(margin:String):UIButton;
    public function onClick(callback:Void->Void):UIButton;
    public function setTextContent(label:String):Void;
}

extern class UICheckbox {
    public function new(checked:Bool);
    public function setLeft(left:String):UICheckbox;
    public function onChange(callback:Void->Void):UICheckbox;
    public function getValue():Bool;
}

extern class UIPanel {
    public function new();
    public function setId(id:String):Void;
    public function add(element:Dynamic):Void;
}

extern class UIInput {
    public function new(value:String);
    public function setLeft(left:String):UIInput;
    public function setWidth(width:String):UIInput;
    public function onChange(callback:Void->Void):UIInput;
    public function getValue():String;
    public function setValue(value:String):Void;
}

extern class UIRow {
    public function new();
    public function add(element:Dynamic):Void;
}

extern class UIText {
    public function new(text:String);
    public function setClass(className:String):UIText;
}

class SidebarProjectApp {
    public function new(editor:Dynamic) {
        var config = editor.config;
        var signals = editor.signals;
        var strings = editor.strings;
        var save = editor.utils.save;

        var container = new UIPanel();
        container.setId('app');

        var headerRow = new UIRow();
        headerRow.add(new UIText(strings.getKey('sidebar/project/app').toUpperCase()));
        container.add(headerRow);

        var titleRow = new UIRow();
        var title = new UIInput(config.getKey('project/title')).setLeft('100px').setWidth('150px').onChange(function() {
            config.setKey('project/title', this.getValue());
        });
        titleRow.add(new UIText(strings.getKey('sidebar/project/app/title')).setClass('Label'));
        titleRow.add(title);
        container.add(titleRow);

        var editableRow = new UIRow();
        var editable = new UICheckbox(config.getKey('project/editable')).setLeft('100px').onChange(function() {
            config.setKey('project/editable', this.getValue());
        });
        editableRow.add(new UIText(strings.getKey('sidebar/project/app/editable')).setClass('Label'));
        editableRow.add(editable);
        container.add(editableRow);

        var isPlaying = false;
        var playButton = new UIButton(strings.getKey('sidebar/project/app/play'));
        playButton.setWidth('170px').setMarginLeft('120px').setMarginBottom('10px').onClick(function() {
            if (isPlaying == false) {
                isPlaying = true;
                playButton.setTextContent(strings.getKey('sidebar/project/app/stop'));
                signals.startPlayer.dispatch();
            } else {
                isPlaying = false;
                playButton.setTextContent(strings.getKey('sidebar/project/app/play'));
                signals.stopPlayer.dispatch();
            }
        });
        container.add(playButton);

        var publishButton = new UIButton(strings.getKey('sidebar/project/app/publish'));
        publishButton.setWidth('170px').setMarginLeft('120px').setMarginBottom('10px').onClick(function() {
            var toZip = new Dynamic();

            var output = editor.toJSON();
            output.metadata.type = 'App';
            Reflect.deleteField(output, 'history');

            output = JSON.stringify(output, null, '\t');
            output = output.replace(~/[\n\t]+([\d\.e\-\[\]]+)/g, '$1');

            toZip['app.json'] = new strToU8(output);

            var title = config.getKey('project/title');

            var manager = new THREE.LoadingManager(function() {
                var zipped = new zipSync(toZip, { level: 9 });
                var blob = new Blob([zipped.buffer], { type: 'application/zip' });
                save(blob, (title != '' ? title : 'untitled') + '.zip');
            });

            var loader = new THREE.FileLoader(manager);
            loader.load('js/libs/app/index.html', function(content) {
                content = content.replace('<!-- title -->', title);
                var includes = [];
                content = content.replace('<!-- includes -->', includes.join('\n\t\t'));
                var editButton = '';
                if (config.getKey('project/editable')) {
                    editButton = [
                        '			var button = document.createElement(\'a\');',
                        '			button.href = \'https://threejs.org/editor/#file=\' + location.href.split(\'/\').slice(0, -1).join(\'/\') + \'/app.json\';',
                        '			button.style.cssText = \'position: absolute; bottom: 20px; right: 20px; padding: 10px 16px; color: #fff; border: 1px solid #fff; border-radius: 20px; text-decoration: none;\';',
                        '			button.target = \'_blank\';',
                        '			button.textContent = \'EDIT\';',
                        '			document.body.appendChild(button);',
                    ].join('\n');
                }
                content = content.replace('\t\t\t/* edit button */', editButton);
                toZip['index.html'] = new strToU8(content);
            });
            loader.load('js/libs/app.js', function(content) {
                toZip['js/app.js'] = new strToU8(content);
            });
            loader.load('../build/three.module.js', function(content) {
                toZip['js/three.module.js'] = new strToU8(content);
            });
        });
        container.add(publishButton);

        signals.editorCleared.add(function() {
            title.setValue('');
            config.setKey('project/title', '');
        });

        return container;
    }
}