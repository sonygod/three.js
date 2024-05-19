package three.js.src.renderers.webgl;

class StructuredUniform {
    public var id:String;
    public var seq:Array<Dynamic>;
    public var map:Map<String, Dynamic>;

    public function new(id:String) {
        this.id = id;
        this.seq = new Array<Dynamic>();
        this.map = new Map<String, Dynamic>();
    }

    public function setValue(gl:Dynamic, value:Dynamic, textures:Dynamic):Void {
        var seq:Array<Dynamic> = this.seq;
        var i:Int = 0;
        var n:Int = seq.length;
        while (i < n) {
            var u:Dynamic = seq[i];
            u.setValue(gl, value[u.id], textures);
            i++;
        }
    }
}