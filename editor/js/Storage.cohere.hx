class Storage {
    static var indexedDB:Dynamic;
    static var name:String = "threejs-editor";
    static var version:Int = 1;
    static var database:Dynamic;

    static function init(callback:Void->Void) {
        var request = indexedDB.open(name, version);
        request.onupgradeneeded = function(event) {
            var db = event.target.result;
            if (!db.objectStoreNames.contains("states")) {
                db.createObjectStore("states");
            }
        };
        request.onsuccess = function(event) {
            database = event.target.result;
            callback();
        };
        request.onerror = function(event) {
            trace("IndexedDB error: " + event);
        };
    }

    static function get(callback:Dynamic->Void) {
        var transaction = database.transaction(["states"], "readonly");
        var objectStore = transaction.objectStore("states");
        var request = objectStore.get(0);
        request.onsuccess = function(event) {
            callback(event.target.result);
        };
    }

    static function set(data:Dynamic) {
        var start = Date.now();
        var transaction = database.transaction(["states"], "readwrite");
        var objectStore = transaction.objectStore("states");
        var request = objectStore.put(data, 0);
        request.onsuccess = function() {
            var end = Date.now();
            trace("Saved state to IndexedDB. Time: " + (end - start) + "ms");
        };
    }

    static function clear() {
        if (database == null) return;
        var transaction = database.transaction(["states"], "readwrite");
        var objectStore = transaction.objectStore("states");
        var request = objectStore.clear();
        request.onsuccess = function() {
            trace("Cleared IndexedDB");
        };
    }

    public function new() {
        if (Sys.browser()) {
            indexedDB = window.indexedDB;
            if (indexedDB == null) {
                trace("Storage: IndexedDB not available.");
            }
        } else {
            trace("Storage: IndexedDB not available outside the browser.");
        }
    }
}