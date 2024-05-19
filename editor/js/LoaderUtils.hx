package three.js.editor.js;

class LoaderUtils {

    public static function createFilesMap(files:Array<Dynamic>):Map<String, Dynamic> {
        var map = new Map<String, Dynamic>();
        for (file in files) {
            map.set(file.name, file);
        }
        return map;
    }

    public static function getFilesFromItemList(items:Array<Dynamic>, onDone:(files:Array<Dynamic>, filesMap:Map<String, Dynamic>)->Void) {
        var itemsCount = 0;
        var itemsTotal = 0;
        var files = new Array<Dynamic>();
        var filesMap = new Map<String, Dynamic>();

        function onEntryHandled() {
            itemsCount++;
            if (itemsCount == itemsTotal) {
                onDone(files, filesMap);
            }
        }

        function handleEntry(entry:Dynamic) {
            if (entry.isDirectory) {
                var reader = entry.createReader();
                reader.readEntries(function(entries:Array<Dynamic>) {
                    for (entry in entries) {
                        handleEntry(entry);
                    }
                    onEntryHandled();
                });
            } else if (entry.isFile) {
                entry.file(function(file:Dynamic) {
                    files.push(file);
                    filesMap.set(entry.fullPath.slice(1), file);
                    onEntryHandled();
                });
            }
            itemsTotal++;
        }

        for (item in items) {
            if (item.kind == 'file') {
                handleEntry(item.webkitGetAsEntry());
            }
        }
    }
}