class LoaderUtils {

    static function createFilesMap(files:Array<Dynamic>):Map<String, Dynamic> {

        var map = new Map<String, Dynamic>();

        for (i in 0...files.length) {

            var file = files[i];
            map.set(file.name, file);

        }

        return map;

    }

    static function getFilesFromItemList(items:Array<Dynamic>, onDone:Dynamic->Void):Void {

        // TOFIX: setURLModifier() breaks when the file being loaded is not in root

        var itemsCount = 0;
        var itemsTotal = 0;

        var files = [];
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
                reader.readEntries(function (entries:Array<Dynamic>) {

                    for (i in 0...entries.length) {

                        handleEntry(entries[i]);

                    }

                    onEntryHandled();

                });

            } else if (entry.isFile) {

                entry.file(function (file:Dynamic) {

                    files.push(file);

                    filesMap.set(entry.fullPath.slice(1), file);
                    onEntryHandled();

                });

            }

            itemsTotal++;

        }

        for (i in 0...items.length) {

            var item = items[i];

            if (item.kind == 'file') {

                handleEntry(item.webkitGetAsEntry());

            }

        }

    }

}