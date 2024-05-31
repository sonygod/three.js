class Cache {
  public static enabled:Bool = false;
  public static files:Map<String,Dynamic> = new Map();

  public static add(key:String, file:Dynamic) {
    if (!Cache.enabled) return;
    // console.log( 'THREE.Cache', 'Adding key:', key );
    Cache.files.set(key, file);
  }

  public static get(key:String):Dynamic {
    if (!Cache.enabled) return;
    // console.log( 'THREE.Cache', 'Checking key:', key );
    return Cache.files.get(key);
  }

  public static remove(key:String) {
    Cache.files.remove(key);
  }

  public static clear() {
    Cache.files = new Map();
  }
}