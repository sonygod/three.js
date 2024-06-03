class LoaderUtils {

    static function createFilesMap(files: Array<File>): haxe.ds.StringMap<File> {
        var map = new haxe.ds.StringMap<File>();
        for (file in files) {
            map.set(file.name, file);
        }
        return map;
    }

    static function getFilesFromItemList(items: Array<FileSystemEntry>, onDone: (Array<File>, haxe.ds.StringMap<File>) -> Void) {
        var itemsCount = 0;
        var itemsTotal = 0;
        var files = new Array<File>();
        var filesMap = new haxe.ds.StringMap<File>();

        function onEntryHandled() {
            itemsCount++;
            if (itemsCount == itemsTotal) {
                onDone(files, filesMap);
            }
        }

        function handleEntry(entry: FileSystemEntry) {
            if (js.Boot.instanceof(entry, js.html.FileSystemDirectoryEntry)) {
                var reader = entry.createReader();
                reader.readEntries(function(entries: Array<FileSystemEntry>) {
                    for (entry in entries) {
                        handleEntry(entry);
                    }
                    onEntryHandled();
                });
            } else if (js.Boot.instanceof(entry, js.html.FileSystemFileEntry)) {
                entry.file(function(file: File) {
                    files.push(file);
                    filesMap.set(entry.fullPath.substring(1), file);
                    onEntryHandled();
                });
            }
            itemsTotal++;
        }

        for (item in items) {
            if (item.kind == "file") {
                handleEntry(item.webkitGetAsEntry());
            }
        }
    }
}