class Config {

    static var name:String = 'threejs-editor';

    static var userLanguage:String = js.Browser.navigator.language.split( '-' )[ 0 ];

    static var suggestedLanguage:String = if (['fr', 'ja', 'zh'].indexOf(userLanguage) != -1) userLanguage else 'en';

    static var storage:Map<String, Dynamic> = {
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

    static function getKey(key:String):Dynamic {
        return storage[key];
    }

    static function setKey(key:String, value:Dynamic):Void {
        storage[key] = value;
        js.Browser.window.localStorage[name] = haxe.Json.stringify(storage);
        trace('[' + /\d\d\:\d\d\:\d\d/.exec(new Date())[0] + ']', 'Saved config to LocalStorage.');
    }

    static function clear():Void {
        delete js.Browser.window.localStorage[name];
    }

}