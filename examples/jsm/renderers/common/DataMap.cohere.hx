class DataMap {
    var data: Map<WeakRef, { dynamic: Dynamic }>;

    public function new() {
        data = Map();
    }

    public function get(object: Dynamic) : { dynamic: Dynamic } {
        if (!data.exists(object)) {
            data.set(object, { });
        }
        return data.get(object);
    }

    public function delete(object: Dynamic) : Void {
        if (data.exists(object)) {
            data.remove(object);
        }
    }

    public function has(object: Dynamic) : Bool {
        return data.exists(object);
    }

    public function dispose() : Void {
        data = Map();
    }
}