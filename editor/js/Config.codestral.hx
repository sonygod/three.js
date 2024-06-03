import js.html.Window;
import js.html.Storage;
import js.html.WebStorage;
import js.json.Json;

class Config {
    private var name:String = "threejs-editor";
    private var userLanguage:String;
    private var suggestedLanguage:String;
    private var storage:Dynamic = new Dynamic();

    public function new() {
        userLanguage = Window.navigator.language.split('-')[0];

        suggestedLanguage = ['fr', 'ja', 'zh'].indexOf(userLanguage) != -1 ? userLanguage : 'en';

        storage = {
            'language': suggestedLanguage,
            'autosave': true,
            'project/title': '',
            'project/editable': false,
            'project/vr': false,
            'project/renderer/antialias': true,
            'project/renderer/shadows': true,
            'project/renderer/shadowType': 1,
            'project/renderer/toneMapping': 0,
            'project/renderer/toneMappingExposure': 1,
            'settings/history': false,
            'settings/shortcuts/translate': 'w',
            'settings/shortcuts/rotate': 'e',
            'settings/shortcuts/scale': 'r',
            'settings/shortcuts/undo': 'z',
            'settings/shortcuts/focus': 'f'
        };

        if (js.html.WebStorage.local[name] == null) {
            js.html.WebStorage.local[name] = Json.stringify(storage);
        } else {
            var data = Json.parse(js.html.WebStorage.local[name]);
            for (key in Reflect.fields(data)) {
                storage[key] = data[key];
            }
        }
    }

    public function getKey(key:String):Dynamic {
        return storage[key];
    }

    public function setKey(args:Dynamic...):Void {
        for (i in 0...args.length) {
            if (i % 2 == 0) {
                storage[args[i]] = args[i + 1];
            }
        }

        js.html.WebStorage.local[name] = Json.stringify(storage);
        trace('[' + Date.now().toString().substring(11, 19) + '] Saved config to LocalStorage.');
    }

    public function clear():Void {
        js.html.WebStorage.local.remove(name);
    }
}