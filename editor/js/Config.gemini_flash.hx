import js.Browser;
import js.Lib;

class Config {

    static var name = 'threejs-editor';
    static var storage:Map<String, Dynamic> = [];

    public static function init():Void {
        var userLanguage = Browser.navigator.language.split('-')[0];
        var suggestedLanguage = ['fr', 'ja', 'zh'].indexOf(userLanguage) != -1 ? userLanguage : 'en';

        var defaultStorage = [
            'language' => suggestedLanguage,
            'autosave' => true,
            'project/title' => '',
            'project/editable' => false,
            'project/vr' => false,
            'project/renderer/antialias' => true,
            'project/renderer/shadows' => true,
            'project/renderer/shadowType' => 1, // PCF
            'project/renderer/toneMapping' => 0, // NoToneMapping
            'project/renderer/toneMappingExposure' => 1,
            'settings/history' => false,
            'settings/shortcuts/translate' => 'w',
            'settings/shortcuts/rotate' => 'e',
            'settings/shortcuts/scale' => 'r',
            'settings/shortcuts/undo' => 'z',
            'settings/shortcuts/focus' => 'f'
        ];

        var storedData = Browser.window.localStorage.getItem(name);

        if (storedData == null) {
            storage = defaultStorage;
            Browser.window.localStorage.setItem(name, JSON.stringify(storage));
        } else {
            try {
                var data:Map<String, Dynamic> = JSON.parse(storedData);
                for (key in defaultStorage.keys()) {
                    storage[key] = data.get(key) != null ? data.get(key) : defaultStorage.get(key);
                }
            } catch (e:Dynamic) {
                storage = defaultStorage;
            }
        }
    }

    public static function getKey(key:String):Dynamic {
        return storage.get(key);
    }

    public static function setKey(?args:Array<Dynamic>):Void {
        if (args == null || args.length % 2 != 0) return;

        for (i in 0...Std.int(args.length / 2)) {
            var key = args[i * 2];
            var value = args[i * 2 + 1];
            storage.set(key, value);
        }

        Browser.window.localStorage.setItem(name, JSON.stringify(storage));

        var date = Date.now().toString().substr(-8, 8); // HH:mm:ss
        trace('[' + date + ']', 'Saved config to LocalStorage.');
    }

    public static function clear():Void {
        Browser.window.localStorage.removeItem(name);
    }
}