package three.js.examples.jsm.transpiler;

import haxe.ds.StringMap;
import haxe.ds.Set;

class TSLEncoder {
    var tab:String;
    var imports:Set<String>;
    var global:Set<String>;
    var overloadings:StringMap<Array<Dynamic>>;
    var layoutsCode:String;
    var iife:Bool;
    var uniqueNames:Bool;
    var reference:Bool;

    var _currentProperties:Map<String, Dynamic>;
    var _lastStatement:Dynamic;

    public function new() {
        tab = "";
        imports = new Set<String>();
        global = new Set<String>();
        overloadings = new StringMap();
        layoutsCode = "";
        iife = false;
        uniqueNames = false;
        reference = false;

        _currentProperties = new Map<String, Dynamic>();
        _lastStatement = null;
    }

    public function addImport(name:String) {
        // import only if it's a node
        name = name.split(".")[0];
        if (Nodes.exists(name) && !global.exists(name) && !_currentProperties.exists(name)) {
            imports.add(name);
        }
    }

    public function emitUniform(node:Dynamic) {
        var code = "const " + node.name + " = ";
        if (reference) {
            addImport("reference");
            global.add(node.name);
            code += "reference( 'value', '" + node.type + "', uniforms[ '" + node.name + "' ] )";
        } else {
            addImport("uniform");
            global.add(node.name);
            code += "uniform( '" + node.type + "' )";
        }
        return code;
    }

    public function emitExpression(node:Dynamic) {
        // ...
    }

    public function emitBody(body:Array<Dynamic>) {
        // ...
    }

    public function emitTernary(node:Dynamic) {
        // ...
    }

    public function emitConditional(node:Dynamic) {
        // ...
    }

    public function emitLoop(node:Dynamic) {
        // ...
    }

    public function emitFor(node:Dynamic) {
        // ...
    }

    public function emitForWhile(node:Dynamic) {
        // ...
    }

    public function emitVariables(node:Dynamic, isRoot:Bool = true) {
        // ...
    }

    public function emitOverloadingFunction(nodes:Array<Dynamic>) {
        // ...
    }

    public function emitFunction(node:Dynamic) {
        // ...
    }

    public function setLastStatement(statement:Dynamic) {
        _lastStatement = statement;
    }

    public function emitExtraLine(statement:Dynamic) {
        // ...
    }

    public function emit(ast:Dynamic) {
        // ...
    }
}