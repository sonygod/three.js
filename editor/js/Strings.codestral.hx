import haxe.ds.StringMap;

class Strings {
    private var values:StringMap<StringMap<String>>;
    private var language:String;

    public function new(config:Dynamic) {
        this.language = config.getKey('language');

        this.values = new StringMap<StringMap<String>>();

        this.values['en'] = new StringMap<String>();
        this.values['en']['prompt/file/open'] = 'Any unsaved data will be lost. Are you sure?';
        // Add the rest of the English translations here

        this.values['fr'] = new StringMap<String>();
        this.values['fr']['prompt/file/open'] = 'Toutes les données non enregistrées seront perdues Êtes-vous sûr ?';
        // Add the rest of the French translations here

        this.values['zh'] = new StringMap<String>();
        this.values['zh']['prompt/file/open'] = '您确定吗？未保存的数据将会丢失。';
        // Add the rest of the Chinese translations here

        this.values['ja'] = new StringMap<String>();
        this.values['ja']['prompt/file/open'] = '保存されていないデータは失われます。 本気ですか？';
        // Add the rest of the Japanese translations here
    }

    public function getKey(key:String):String {
        return this.values[this.language].exists(key) ? this.values[this.language].get(key) : '???';
    }
}