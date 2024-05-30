class Storage {

    public function new() {

        var indexedDB = js.Browser.window.indexedDB;

        if (indexedDB == null) {

            js.Browser.console.warn('Storage: IndexedDB not available.');
            return {
                init: function () {},
                get: function () {},
                set: function () {},
                clear: function () {}
            };

        }

        var name = 'threejs-editor';
        var version = 1;

        var database:js.html.IDBDatabase;

        return {

            init: function (callback) {

                var request = indexedDB.open(name, version);
                request.onupgradeneeded = function (event) {

                    var db = event.target.result;

                    if (db.objectStoreNames.contains('states') === false) {

                        db.createObjectStore('states');

                    }

                };

                request.onsuccess = function (event) {

                    database = event.target.result;

                    callback();

                };

                request.onerror = function (event) {

                    js.Browser.console.error('IndexedDB', event);

                };


            },

            get: function (callback) {

                var transaction = database.transaction(['states'], 'readonly');
                var objectStore = transaction.objectStore('states');
                var request = objectStore.get(0);
                request.onsuccess = function (event) {

                    callback(event.target.result);

                };

            },

            set: function (data) {

                var start = js.Browser.performance.now();

                var transaction = database.transaction(['states'], 'readwrite');
                var objectStore = transaction.objectStore('states');
                var request = objectStore.put(data, 0);
                request.onsuccess = function () {

                    js.Browser.console.log('[' + /\d\d\:\d\d\:\d\d/.exec(new Date())[0] + ']', 'Saved state to IndexedDB. ' + (js.Browser.performance.now() - start).toFixed(2) + 'ms');

                };

            },

            clear: function () {

                if (database == null) return;

                var transaction = database.transaction(['states'], 'readwrite');
                var objectStore = transaction.objectStore('states');
                var request = objectStore.clear();
                request.onsuccess = function () {

                    js.Browser.console.log('[' + /\d\d\:\d\d\:\d\d/.exec(new Date())[0] + ']', 'Cleared IndexedDB.');

                };

            }

        };

    }

}