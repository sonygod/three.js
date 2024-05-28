import haxe.io.Bytes;

class HemisphereLightHelper extends Object3D {
    var light:Dynamic;
    var size:Float;
    var color:Float;
    var matrix:Matrix4;
    var matrixAutoUpdate:Bool;
    var type:String;
    var geometry:OctahedronGeometry;
    var material:MeshBasicMaterial;
    var position:Float32Array;
    var colors:Float32Array;
    var _vector:Vector3;
    var _color1:Color;
    var _color2:Color;

    public function new(light:Dynamic, size:Float, ?color:Float) {
        super();
        this.light = light;
        this.matrix = light.matrixWorld;
        this.matrixAutoUpdate = false;
        this.color = color;
        this.type = 'HemisphereLightHelper';
        geometry = new OctahedronGeometry(size);
        geometry.rotateY(Math.PI * 0.5);
        material = new MeshBasicMaterial({ wireframe: true, fog: false, toneMapped: false });
        if (color == null)
            material.vertexColors = true;
        position = geometry.getAttribute('position');
        colors = new Float32Array(position.length * 3);
        geometry.setAttribute('color', new BufferAttribute(colors, 3));
        add(new Mesh(geometry, material));
        update();
    }

    public function dispose() {
        get_children()[0].geometry.dispose();
        get_children()[0].material.dispose();
    }

    public function update() {
        var mesh = get_children()[0];
        if (color != null) {
            material.color.set(color);
        } else {
            var colors = mesh.geometry.getAttribute('color');
            _color1.copy(light.color);
            _color2.copy(light.groundColor);
            var i = 0;
            while (i < colors.count) {
                var color = if (i < (colors.count / 2)) _color1 else _color2;
                colors.setXYZ(i, color.r, color.g, color.b);
                i += 1;
            }
            colors.needsUpdate = true;
        }
        light.updateWorldMatrix(true, false);
        mesh.lookAt(_vector.setFromMatrixPosition(light.matrixWorld).negate());
    }
}

class OctahedronGeometry extends Geometry {
    public function new(radius:Float, ?detail:Int) {
        super();
    }
}

class MeshBasicMaterial extends Material {
    public var wireframe:Bool;
    public var vertexColors:Bool;
    public var fog:Bool;
    public var toneMapped:Bool;
    public var color:Color;

    public function new(?args:Dynamic) {
        super();
        if (args != null) {
            wireframe = args.wireframe;
            vertexColors = args.vertexColors;
            fog = args.fog;
            toneMapped = args.toneMapped;
            color = args.color;
        }
    }
}

class Color {
    public var r:Float;
    public var g:Float;
    public var b:Float;

    public function copy(other:Color) {
        r = other.r;
        g = other.g;
        b = other.b;
    }

    public function set(value:Float) {
        r = value;
        g = value;
        b = value;
    }
}

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function setFromMatrixPosition(m:Matrix4) {
        x = m.elements[12];
        y = m.elements[13];
        z = m.elements[14];
    }

    public function negate() {
        x = -x;
        y = -y;
        z = -z;
    }
}

class Object3D {
    public function add(obj:Dynamic) {
        // ...
    }

    public function get_children() :Array<Dynamic> {
        // ...
    }
}

class Mesh {
    public function new(geometry:Dynamic, material:Dynamic) {
        // ...
    }
}

class Geometry {
    public function getAttribute(name:String) :Float32Array {
        // ...
    }

    public function setAttribute(name:String, value:Dynamic) {
        // ...
    }

    public var attributes:Dynamic;
}

class Material {
    public function dispose() {
        // ...
    }
}

class Float32Array {
    public var length:Int;
}

class Matrix4 {
    public var elements:Float;
}

class BufferAttribute {
    public function new(array:Float32Array, itemSize:Int) {
        // ...
    }
}

class Dynamic {
}