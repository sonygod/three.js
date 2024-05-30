package three.js.editor.js;

import js.html.Storage;
import js.html.Window;

class Config {
  private static var NAME:String = 'threejs-editor';
  private static var STORAGE:Storage;
  private var storage:Map<String, Dynamic>;

  public function new() {
    var userLanguage:String = Window.navigator.language.split('-')[0];
    var suggestedLanguage:String = ['fr', 'ja', 'zh'].indexOf(userLanguage) != -1 ? userLanguage : 'en';

    storage = [
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

    if (Window.localStorage.getItem(NAME) == null) {
      Window.localStorage.setItem(NAME, Json.stringify(storage));
    } else {
      var data:Map<String, Dynamic> = Json.parse(Window.localStorage.getItem(NAME));
      for (key in data.keys()) {
        storage[key] = data[key];
      }
    }
  }

  public function getKey(key:String):Dynamic {
    return storage[key];
  }

  public function setKey(args:Array<Dynamic>) {
    for (i in 0...args.length) {
      storage[args[i]] = args[i + 1];
    }
    Window.localStorage.setItem(NAME, Json.stringify(storage));
    trace('[' + Date.now().toTimeString().substr(0, 8) + '] Saved config to LocalStorage.');
  }

  public function clear() {
    Window.localStorage.removeItem(NAME);
  }
}