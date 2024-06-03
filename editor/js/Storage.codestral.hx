class Storage {

    private var name = 'threejs-editor';
    private var version = 1;
    private var database:IDBDatabase;

    public function new() {
        var indexedDB = js.Browser.window.indexedDB;

        if (indexedDB == null) {
            trace('Storage: IndexedDB not available.');
            return;
        }
    }

    public function init(callback:Void -> Void):Void {
        var request = indexedDB.open(name, version);
        request.onupgradeneeded = function(event) {
            var db = event.target.result;

            if (!db.objectStoreNames.contains('states')) {
                db.createObjectStore('states');
            }
        };

        request.onsuccess = function(event) {
            database = event.target.result;
            callback();
        };

        request.onerror = function(event) {
            trace('IndexedDB', event);
        };
    }

    public function get(callback:Dynamic -> Void):Void {
        var transaction = database.transaction(['states'], 'readonly');
        var objectStore = transaction.objectStore('states');
        var request = objectStore.get(0);
        request.onsuccess = function(event) {
            callback(event.target.result);
        };
    }

    public function set(data:Dynamic):Void {
        var start = js.Browser.window.performance.now();

        var transaction = database.transaction(['states'], 'readwrite');
        var objectStore = transaction.objectStore('states');
        var request = objectStore.put(data, 0);
        request.onsuccess = function() {
            var date = new Date();
            var time = date.getHours() + ":" + date.getMinutes() + ":" + date.getSeconds();
            trace('[' + time + ']', 'Saved state to IndexedDB. ' + ((js.Browser.window.performance.now() - start).toFixed(2)) + 'ms');
        };
    }

    public function clear():Void {
        if (database == null) return;

        var transaction = database.transaction(['states'], 'readwrite');
        var objectStore = transaction.objectStore('states');
        var request = objectStore.clear();
        request.onsuccess = function() {
            var date = new Date();
            var time = date.getHours() + ":" + date.getMinutes() + ":" + date.getSeconds();
            trace('[' + time + ']', 'Cleared IndexedDB.');
        };
    }
}