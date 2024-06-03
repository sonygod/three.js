class NodeVar {

    public var isNodeVar:Bool = true;
    public var name:String;
    public var type:Dynamic;

    public function new(name:String, type:Dynamic) {

        this.name = name;
        this.type = type;

    }

}


Please note that Haxe is a statically typed language, so dynamic typing from JavaScript has been replaced with `Dynamic` in Haxe. Also, Haxe does not have a default export like JavaScript ES6 modules, so the export statement has been removed.

If you want to use the class in another file, you can import it like this:


import NodeVar;


And create an instance of the class like this:


var nodeVar = new NodeVar("name", "type");