package three.js.editor.js;

import js.html.IndexedDB;
import js.html.IDBDatabase;
import js.html.IDBRequest;
import js.html.IDBTransaction;
import js.html.IDBObjectStore;
import haxe.Timer;

class Storage {
  private var indexedDB:IndexedDB;
  private var database:IDBDatabase;
  private var name:String = 'threejs-editor';
  private var version:Int = 1;

  public function new() {
    indexedDB = js.Browser.window.indexedDB;
    if (indexedDB == null) {
      js.Browser.console.warn('Storage: IndexedDB not available.');
      init = function(callback:{}) {};
      get = function(callback:{}) {};
      set = function(data:Dynamic) {};
      clear = function() {};
      return;
    }
  }

  public function init(callback:{}) {
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
      js.Browser.console.error('IndexedDB', event);
    };
  }

  public function get(callback:{->Void}) {
    var transaction = database.transaction(['states'], 'readonly');
    var objectStore = transaction.objectStore('states');
    var request = objectStore.get(0);
    request.onsuccess = function(event) {
      callback(event.target.result);
    };
  }

  public function set(data:Dynamic) {
    var start = Timer.stamp();
    var transaction = database.transaction(['states'], 'readwrite');
    var objectStore = transaction.objectStore('states');
    var request = objectStore.put(data, 0);
    request.onsuccess = function() {
      js.Browser.console.log('[' + DateTools.format(Date.now(), '%H:%M:%S') + ']', 'Saved state to IndexedDB. ' + (Timer.stamp() - start).toFixed(2) + 'ms');
    };
  }

  public function clear() {
    if (database == null) return;
    var transaction = database.transaction(['states'], 'readwrite');
    var objectStore = transaction.objectStore('states');
    var request = objectStore.clear();
    request.onsuccess = function() {
      js.Browser.console.log('[' + DateTools.format(Date.now(), '%H:%M:%S') + ']', 'Cleared IndexedDB.');
    };
  }
}