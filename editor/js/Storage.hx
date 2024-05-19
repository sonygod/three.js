package three.js.editor.js;

import js.html.IndexedDB;
import js.html.IDBDatabase;
import js.html.IDBObjectStore;
import js.html.IDBTransaction;
import js.html.IDBRequest;

class Storage {

    private static var indexedDB:IndexedDB = untyped window.indexedDB;

    public function new() {
        if (indexedDB == null) {
            trace("Storage: IndexedDB not available.");
            return {
                init: function() {},
                get: function() {},
                set: function() {},
                clear: function() {}
            };
        }

        var name = 'threejs-editor';
        var version = 1;

        var database:IDBDatabase = null;

        return {
            init: function(callback) {
                var request:IDBRequest = indexedDB.open(name, version);
                request.onupgradeneeded = function(event) {
                    var db:IDBDatabase = event.target.result;
                    if (!db.objectStoreNames.contains('states')) {
                        db.createObjectStore('states');
                    }
                };

                request.onsuccess = function(event) {
                    database = event.target.result;
                    callback();
                };

                request.onerror = function(event) {
                    trace("IndexedDB", event);
                };
            },

            get: function(callback) {
                var transaction:IDBTransaction = database.transaction(['states'], 'readonly');
                var objectStore:IDBObjectStore = transaction.objectStore('states');
                var request:IDBRequest = objectStore.get(0);
                request.onsuccess = function(event) {
                    callback(event.target.result);
                };
            },

            set: function(data) {
                var start:Float = haxe.Timer.stamp();
                var transaction:IDBTransaction = database.transaction(['states'], 'readwrite');
                var objectStore:IDBObjectStore = transaction.objectStore('states');
                var request:IDBRequest = objectStore.put(data, 0);
                request.onsuccess = function() {
                    trace('[' + Date.now() + ']', 'Saved state to IndexedDB. ' + (haxe.Timer.stamp() - start) + 'ms');
                };
            },

            clear: function() {
                if (database == null) return;
                var transaction:IDBTransaction = database.transaction(['states'], 'readwrite');
                var objectStore:IDBObjectStore = transaction.objectStore('states');
                var request:IDBRequest = objectStore.clear();
                request.onsuccess = function() {
                    trace('[' + Date.now() + ']', 'Cleared IndexedDB.');
                };
            }
        };
    }
}