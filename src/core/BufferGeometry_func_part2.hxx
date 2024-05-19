class BufferGeometry {
    var index:Null<BufferAttribute>;
    var attributes:Map<String, BufferAttribute>;
    var morphAttributes:Map<String, Array<BufferAttribute>>;
    var groups:Array<{start:Int, count:Int, materialIndex:Int}>;
    var boundingBox:Null<Box3>;
    var boundingSphere:Null<Sphere>;
    var drawRange:{start:Int, count:Int};
    var userData:Dynamic;

    function new() {
        this.index = null;
        this.attributes = new Map();
        this.morphAttributes = new Map();
        this.groups = [];
        this.boundingBox = null;
        this.boundingSphere = null;
        this.drawRange = {start: 0, count: 0};
        this.userData = null;
    }

    function computeTangents() {
        // 省略...
    }

    function computeVertexNormals() {
        // 省略...
    }

    function normalizeNormals() {
        // 省略...
    }

    function toNonIndexed() {
        // 省略...
    }

    function toJSON() {
        // 省略...
    }

    function clone() {
        // 省略...
    }

    function copy(source:BufferGeometry) {
        // 省略...
    }

    function dispose() {
        // 省略...
    }
}