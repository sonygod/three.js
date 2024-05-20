class StructuredUniform {

    public var id:String;
    public var seq:Array<Dynamic>;
    public var map:haxe.ds.StringMap<Dynamic>;

    public function new(id:String) {
        this.id = id;
        this.seq = [];
        this.map = new haxe.ds.StringMap();
    }

    public function setValue(gl:Dynamic, value:Dynamic, textures:Dynamic):Void {
        var seq = this.seq;
        for (i in 0...seq.length) {
            var u = seq[i];
            u.setValue(gl, value[u.id], textures);
        }
    }
}