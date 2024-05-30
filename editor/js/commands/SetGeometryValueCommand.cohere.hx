import Command from '../Command.hx';

class SetGeometryValueCommand extends Command {
    public var object:Object3D;
    public var attributeName:String;
    public var oldValue:Dynamic;
    public var newValue:Dynamic;

    public function new(editor:Editor, ?object:Object3D, attributeName:String, newValue:Dynamic) {
        super(editor);

        this.type = 'SetGeometryValueCommand';
        this.name = editor.strings.getKey('command/SetGeometryValue') + ': ' + attributeName;

        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? object.geometry[attributeName] : null;
        this.newValue = newValue;
    }

    public function execute() {
        this.object.geometry[this.attributeName] = this.newValue;
        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.geometryChanged.dispatch();
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo() {
        this.object.geometry[this.attributeName] = this.oldValue;
        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.geometryChanged.dispatch();
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        output.objectUuid = this.object.uuid;
        output.attributeName = this.attributeName;
        output.oldValue = this.oldValue;
        output.newValue = this.newValue;
        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);
        this.object = this.editor.objectByUuid(json.objectUuid);
        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
    }

    public static function __hx_createDynamic() {
        return new haxe.lang.DynamicObject(null, null, new haxe.lang.DynamicObject(null, [
            "new", "fromJSON", "toJSON", "undo", "execute"
        ], null, null));
    }
}

class haxe_ds_StringMap {
    public var h:Array<Dynamic>;

    public function new(?size:Int, ?hash:Dynamic) {
        this.h = (if (size == null) Array_Impl._new(0) else Array_Impl._new(size));
        if (hash != null) {
            this.h.__hash = hash;
        }
    }

    public function set(key:String, value:Dynamic) {
        var x = this.h.__find(key);
        if (x >= 0) {
            this.h[x] = value;
        } else {
            this.h.push(key);
            this.h.push(value);
        }
    }

    public function get(key:String):Dynamic {
        var x = this.h.__find(key);
        if (x >= 0) {
            return this.h[x + 1];
        } else {
            return null;
        }
    }

    public function exists(key:String):Bool {
        return this.h.__find(key) >= 0;
    }

    public function remove(key:String):Bool {
        var x = this.h.__find(key);
        if (x >= 0) {
            this.h.splice(x, 2);
            return true;
        } else {
            return false;
        }
    }

    public function keys():Array<String> {
        var k = this.h.slice();
        var len = k.length / 2;
        var ret = new Array<String>();
        {
            var _g = 0;
            while (_g < len) {
                var i = _g++;
                ret.push(k[i]);
            }
        }
        return ret;
    }

    public function iterator():Dynamic {
        return { ref : this.h.iterator(), idx : 0};
    }

    public function __find(k:String):Int {
        var h = this.h;
        var n = h.length;
        var idx = 0;
        var hash = h.__hash;
        if (hash != null) {
            var hk = hash(k);
            var i = (if (hk == null) null else hk & 0);
            while(true) {
                var x = h[idx];
                if ((x == k || (i == hk && k == x))) {
                    return idx;
                }
                if (++ idx >= n) {
                    idx = 0;
                }
                if (idx == i) {
                    return -1;
                }
            }
        } else {
            while(true) {
                var x1 = h[idx];
                if (x1 == k) {
                    return idx;
                }
                if (++ idx >= n) {
                    idx = 0;
                }
            }
        }
    }

    public static function __hx_createDynamic() {
        return new haxe_ds_StringMap(null, null);
    }
}

class haxe_IMap {
    public var h:Dynamic;

    public function new(?size:Int, ?hash:Dynamic) {
    }

    public function exists(key:Dynamic):Bool {
        return false;
    }

    public function get(key:Dynamic):Dynamic {
        return null;
    }

    public function keys():Dynamic {
        return [];
    }

    public function iterator():Dynamic {
        return null;
    }

    public function remove(key:Dynamic):Bool {
        return false;
    }

    public function set(key:Dynamic, value:Dynamic):Void {
    }

    public static function __hx_createEmpty() {
        return new haxe_IMap(null, null);
    }
}

class haxe_ds_ObjectMap {
    public var h:haxe_ds_StringMap;

    public function new(?size:Int, ?hash:Dynamic) {
        this.h = new haxe_ds_StringMap(size, hash);
    }

    public function exists(key:Dynamic):Bool {
        return this.h.exists(key);
    }

    public function get(key:Dynamic):Dynamic {
        return this.h.get(key);
    }

    public function set(key:Dynamic, value:Dynamic):Dynamic {
        return this.h.set(key, value);
    }

    public function keys():Dynamic {
        return this.h.keys();
    }

    public function iterator():Dynamic {
        return this.h.iterator();
    }

    public function remove(key:Dynamic):Bool {
        return this.h.remove(key);
    }

    public static function __hx_createDynamic() {
        return new haxe_ds_ObjectMap(null, null);
    }
}

class haxe_ds_GenericStack {
    public var stack:Array<Dynamic>;

    public function new() {
        this.stack = [];
    }

    public function add(item:Dynamic) {
        this.stack.push(item);
    }

    public function pop():Dynamic {
        return this.stack.pop();
    }

    public function isEmpty():Bool {
        return this.stack.length == 0;
    }

    public static function __hx_createEmpty() {
        return new haxe_ds_GenericStack();
    }
}

class haxe_ds_GenericCell {
    public var item:Dynamic;
    public var next:haxe_ds_GenericCell;

    public function new(?item:Dynamic, ?next:haxe_ds_GenericCell) {
        this.item = item;
        this.next = (if (next == null) null else next);
    }

    public static function __hx_createEmpty() {
        return new haxe_ds_GenericCell(null, null);
    }
}

class haxe_ds_GenericCell_haxe_ds_Vector {
    public var elt:Dynamic;
    public var next:haxe_ds_GenericCell_haxe_ds_Vector;

    public function new(?elt:Dynamic, ?next:haxe_ds_GenericCell_haxe_ds_Vector) {
        this.elt = elt;
        this.next = (if (next == null) null else next);
    }

    public static function __hx_createEmpty() {
        return new haxe_ds_GenericCell_haxe_ds_Vector(null, null);
    }
}

class haxe_ds_Vector {
    public var a:Array<Dynamic>;
    public var h:Dynamic;
    public var q:Dynamic;

    public function new(?length:Int, ?data:Dynamic) {
        if (length == null) {
            length = 0;
        }
        if (data == null) {
            data = [];
        }
        this.a = (if ((length == 0 && data == null)) [] else data);
        this.h = { length : this.a.length, _length : -1, _bank : -1, _mode : "vector" };
    }

    public function set_length(length:Int) {
        var d = this.a;
        var len = d.length;
        if (length < this.h.length) {
            this.h.length = length;
        } else if (length > len) {
            this.h._length = length;
            var i = len;
            while(i < length) {
                d.push(null);
                ++ i;
            }
        }
    }

    public function get(index:Int):Dynamic {
        return this.a[index];
    }

    public function set(index:Int, value:Dynamic) {
        var d = this.a;
        var len = d.length;
        if (index < 0 || index >= len || index >= this.h.length) {
            throw haxe_Exception.thrown(haxe.io.Error.OutsideBounds);
        }
        return d[index] = value;
    }

    public function iterator():Dynamic {
        return { ref : this.a.iterator(), idx : 0};
    }

    public function push(x:Dynamic) {
        this.a.push(x);
        ++ this.h.length;
    }

    public function pop():Dynamic {
        var d = this.a;
        if (d.length == 0) {
            return null;
        }
        var len = d.length;
        this.h.length = len - 1;
        return d.pop();
    }

    public function unshift(x:Dynamic) {
        var d = this.a;
        var len = d.length;
        this.h.length = len + 1;
        d.unshift(x);
    }

    public function shift():Dynamic {
        var d = this.a;
        if (d.length == 0) {
            return null;
        }
        this.h.length = d.length - 1;
        return d.shift();
    }

    public function join(sep:String):String {
        return this.a.join(sep);
    }

    public function map(f:Dynamic):Dynamic {
        return this.a.map(f);
    }

    public function __iterator():Dynamic {
        return { ref : this.a.iterator(), idx : 0};
    }

    public static function __hx_createEmpty() {
        return new haxe_ds_Vector(null, null);
    }
}

class haxe_ds_Option {
    public var x:Dynamic;

    public function new(?x:Dynamic) {
        this.x = x;
    }

    public static function Some(v:Dynamic) {
        return new haxe_ds_Option(v);
    }

    public static function None() {
        return new haxe_ds_Option(null);
    }

    public static function __hx_createEmpty() {
        return new haxe_ds_Option(null);
    }
}

class haxe_ds_Either {
    public var _hx_index:Int;
    public var _0:Dynamic;
    public var _1:Dynamic;

    public function new(_0:Dynamic, _1:Dynamic) {
        this._0 = _0;
        this._1 = _1;
    }

    public static function Left(v:Dynamic) {
        return new haxe_ds_Either(v, null);
    }

    public static function Right(v:Dynamic) {
        return new haxe_ds_Either(null, v);
    }

    public static function __hx_createEmpty() {
        return new haxe_ds_Either(null, null);
    }
}

class haxe_ds_ArraySort {
    public static function sort(a:Array<Dynamic>, cmp:Dynamic) {
        a.sort(cmp);
    }

    public static function sortBy(a:Array<Dynamic>, f:Dynamic, cmp:Dynamic) {
        a.sort(function(a1, b1) {
            return cmp(f(a1), f(b1));
        });
    }

    public static function sortOn(a:Array<Dynamic>, f:Dynamic) {
        a.sort(function(a1, b1) {
            var a2 = f(a1);
            var b2 = f(b1);
            if (a2 == b2) {
                return 0;
            } else if (a2 > b2) {
                return 1;
            } else {
                return -1;
            }
        });
    }

    public static function __hx_createEmpty() {
        return new haxe_ds_ArraySort();
    }
}

class haxe_ds_TreeNode {
    public var left:haxe_ds_TreeNode;
    public var right:haxeBins_TreeNode;
    public var elm:Dynamic;

    public function new(?left:haxe_ds_TreeNode, ?right:haxe_ds_TreeNode, ?elm:Dynamic) {
        this.left = (if (left == null) null else left);
        this.right = (if (right == null) null else right);
        this.elm = elm;
    }

    public static function __hx_createEmpty() {
        return new haxe_ds_TreeNode(null, null, null);
    }
}

class haxe_ds_BalancedTree {
    public var root:haxe_ds_TreeNode;
    public var _size:Int;

    public function new() {
        this._size = 0;
    }

    public function set_root(r:haxe_ds_TreeNode) {
        this.root = r;
    }

    public function get_root():haxe_ds_TreeNode {
        return this.root;
    }

    public function get_size():Int {
        return this._size;
    }

    public function set_size(s:Int) {
        this._size = s;
    }

    public function isEmpty():Bool {
        return this._size == 0;
    }

    public function __hx_delete(v:Dynamic) {
        this.root = this.__delete(this.root, v);
    }

    public function __delete(n:haxe_ds_TreeNode, v:Dynamic):haxe_ds_TreeNode {
        if (n == null) {
            return null;
        }
        if (this.__compare(v, n.elm) < 0) {
            n.left = this.__delete(n.left, v);
        } else if (this.__compare(v, n.elm) > 0) {
            n.right = this.__delete(n.right, v);
        } else {
            if (n.left == null) {
                return n.right;
            } else if (n.right == null) {
                return n.left;
            } else {
                var tmp = this.__first(n.right);
                n.elm = tmp.elm;
                n.right = this.__delete(n.right, tmp.elm);
            }
        }
        return n;
    }

    public function __first(n:haxe_ds_TreeNode):haxe_ds_TreeNode {
        if (n.left == null) {
            return n;
        } else {
            return this.__first(n.left);
       Iterations.hx: while(true) {
            var n1 = n.left;
            var n2 = n1.right;
            if (n2 == null) {
                break Iterations.hx;
            }
            n = n1;
        }
        }
        return n;
    }

    public function __compare(a:Dynamic, b:Dynamic):Int {
        if (a == b) {
            return 0;
        } else if (a == null) {
            return -1;
        } else if (b == null) {
            return 1;
        } else {
            return Type.enumIndex(a) - Type.enumIndex(b);
        }
    }

    public static function __hx_createEmpty() {
        return new haxe_ds_BalancedTree();
    }
}

class haxe_ds_EnumValueMap {
    public var h:haxe_ds_BalancedTree;

    public function new(?size:Int, ?hash:Dynamic) {
        this.h = new haxe_ds_BalancedTree();
    }

    public function exists(key:Dynamic):Bool {
        return this.h.exists(key);
    }

    public function get(key:Dynamic):Dynamic {
        var n = this.h.root;
        while(n != null) {
            switch(n.elm._hx_index) {
            case 0:
                var n1 = n;
                var k = n1.elm;
                if (k == key) {
                    return n1.right;
                } else {
                    n = n1.left;
                }
                break;
            case 1:
                return n.elm;
                break;
            }
        }
        return null;
    }

    public function set(key:Dynamic, value:Dynamic) {
        var n = this.h.root;
        while(n != null) {
            switch(n.elm._hx_index) {
            case