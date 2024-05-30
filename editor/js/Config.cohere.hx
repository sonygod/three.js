class Config {
    private static var _name = 'threejs-editor';
    private static var _storage:Dynamic;

    public static function new() {
        var userLanguage = Sys.browser.navigator.language.split('-')[0];
        var suggestedLanguage = ['fr', 'ja', 'zh'].contains(userLanguage) ? userLanguage : 'en';

        _storage = {
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

        var data = window.localStorage.getItem(_name);
        if (data != null) {
            var jsonData = Json.parse(data);
            for (key in jsonData) {
                _storage[key] = jsonData[key];
            }
        } else {
            window.localStorage.setItem(_name, Json.stringify(_storage));
        }
    }

    public static function getKey(key:String):Dynamic {
        return _storage[key];
    }

    public static function setKey(args:Array<Dynamic>) {
        for (i in 0...args.length/2) {
            _storage[args[i]] = args[i+1];
        }
        window.localStorage.setItem(_name, Json.stringify(_storage));
        trace('[' + Date.now().toString().split('.')[0] + ']', 'Saved config to LocalStorage.');
    }

    public static function clear() {
        window.localStorage.removeItem(_name);
    }
}