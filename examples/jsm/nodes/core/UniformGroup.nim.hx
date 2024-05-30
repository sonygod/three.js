class UniformGroup {
    public var name: String;
    public var isUniformGroup: Bool = true;

    public function new(name: String) {
        this.name = name;
    }
}


Note: Haxe does not have a direct equivalent to JavaScript's `export default`. Instead, you would typically just use the class name to reference it in other files. If you want to export it as a default, you can use a module and export it like this:


module three.examples.jsm.nodes.core;

class UniformGroup {
    public var name: String;
    public var isUniformGroup: Bool = true;

    public function new(name: String) {
        this.name = name;
    }
}

export default UniformGroup;