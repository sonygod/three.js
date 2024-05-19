class Strings {

	private var language:String;
	private var values:Map<String, Map<String, String>>;

	public function new(config:Dynamic) {
		language = config.language;
		values = new Map<String, Map<String, String>>();
		values.set("en", new Map<String, String>());
		values.set("fr", new Map<String, String>());
		values.set("zh", new Map<String, String>());
		values.set("ja", new Map<String, String>());

		initEn();
		initFr();
		initZh();
		initJa();
	}

	private function initEn():Void {
		values.get("en").set('prompt/file/open', 'Any unsaved data will be lost. Are you sure?');
		// ... continue initializing the en map
	}

	private function initFr():Void {
		values.get("fr").set('prompt/file/open', 'Toutes les données non enregistrées seront perdues Êtes-vous sûr ?');
		// ... continue initializing the fr map
	}

	private function initZh():Void {
		values.get("zh").set('prompt/file/open', '您确定吗？未保存的数据将会丢失。');
		// ... continue initializing the zh map
	}

	private function initJa():Void {
		values.get("ja").set('prompt/file/open', '保存されていないデータは失われます。 本気ですか？');
		// ... continue initializing the ja map
	}

	public function getKey(key:String):String {
		return values.get(language).get(key) ?? "???";
	}
}