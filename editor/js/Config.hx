package three.js.editor.js;

class Config {
    private var storage:Dynamic = {};
    private var name:String = 'threejs-editor';

    public function new() {
        var userLanguage:String = js.Browser.navigator.language.split('-')[0];
        var suggestedLanguage:String = [ 'fr', 'ja', 'zh' ].indexOf(userLanguage) != -1 ? userLanguage : 'en';

        storage = {
            'language': suggestedLanguage,
            'autosave': true,
            'project/title': '',
            'project/editable': false,
            'project/vr': false,
            'project/renderer/antialias': true,
            'project/renderer/shadows': true,
            'project/renderer/shadowType': 1, // PCF
            'project/renderer/toneMapping': 0, // NoToneMapping
            'project/renderer/toneMappingExposure': 1,
            'settings/history': false,
            'settings/shortcuts/translate': 'w',
            'settings/shortcuts/rotate': 'e',
            'settings/shortcuts/scale': 'r',
            'settings/shortcuts/undo': 'z',
            'settings/shortcuts/focus': 'f'
        };

        if (js.Browser.getLocalStorage().getItem(name) == null) {
            js.Browser.getLocalStorage().setItem(name, Json.stringify(storage));
        } else {
            var data:Dynamic = Json.parse(js.Browser.getLocalStorage().getItem(name));
            for (key in data) {
                storage[key] = data[key];
            }
        }
    }

    public function getKey(key:String):Dynamic {
        return storage[key];
    }

    public function setKey(args:Array<Dynamic>):Void {
        for (i in 0...args.length) {
            storage[args[i]] = args[i + 1];
        }
        js.Browser.getLocalStorage().setItem(name, Json.stringify(storage));
        trace('[' + Date.now().toString() + ']', 'Saved config to LocalStorage.');
    }

    public function clear():Void {
        js.Browser.getLocalStorage().removeItem(name);
    }
}