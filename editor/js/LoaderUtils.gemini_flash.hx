import js.lib.Promise;

class LoaderUtils {

	public static function createFilesMap(files:Array<File>):Map<String, File> {
		var map = new Map<String, File>();
		for (i in 0...files.length) {
			var file = files[i];
			map.set(file.name, file);
		}
		return map;
	}

	public static function getFilesFromItemList(items:Array<Dynamic>, onDone:(files:Array<File>, filesMap:Map<String, File>) -> Void):Void {
		var itemsCount = 0;
		var itemsTotal = 0;

		var files:Array<File> = [];
		var filesMap = new Map<String, File>();

		function onEntryHandled():Void {
			itemsCount++;
			if (itemsCount == itemsTotal) {
				onDone(files, filesMap);
			}
		}

		function handleEntry(entry:Dynamic):Void {
			if (Reflect.hasField(entry, "isDirectory") && entry.isDirectory) {
				var reader = entry.createReader();
				reader.readEntries(function(entries:Array<Dynamic>):Void {
					for (i in 0...entries.length) {
						handleEntry(entries[i]);
					}
					onEntryHandled();
				});
			} else if (Reflect.hasField(entry, "isFile") && entry.isFile) {
				entry.file(function(file:File):Void {
					files.push(file);
					filesMap.set(entry.fullPath.substr(1), file);
					onEntryHandled();
				});
			}

			itemsTotal++;
		}

		for (i in 0...items.length) {
			var item = items[i];
			if (Reflect.hasField(item, "kind") && item.kind == "file") {
				handleEntry(item.webkitGetAsEntry());
			}
		}
	}
}