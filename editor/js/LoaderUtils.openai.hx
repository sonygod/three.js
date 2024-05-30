package three.js.editor.js;

class LoaderUtils {
    public static function createFilesMap(files:Array<File>):Map<String, File> {
        var map = new Map<String, File>();
        for (file in files) {
            map.set(file.name, file);
        }
        return map;
    }

    public static function getFilesFromItemList(items:Array<dyn>, onDone:(files:Array<File>, filesMap:Map<String, File>)->Void) {
        var itemsCount = 0;
        var itemsTotal = 0;
        var files:Array<File> = [];
        var filesMap:Map<String, File> = new Map<String, File>();

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
                entry.file(function(file:File) {
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