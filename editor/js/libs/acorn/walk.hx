package acorn.walk;

import haxe.ds.StringMap;

class Walker {
    static public function simple(node:Dynamic, visitors:Dynamic, base:Dynamic, state:Dynamic):Void {
        if (!base) base = exports.base;
        simpleWalk(node, state, visitors, base);
    }

    static private function simpleWalk(node:Dynamic, st:Dynamic, visitors:Dynamic, base:Dynamic):Void {
        var type = node.type;
        var found = visitors[type];
        base[type](node, st, simpleWalk);
        if (found) found(node, st);
    }

    static public function ancestor(node:Dynamic, visitors:Dynamic, base:Dynamic, state:Dynamic):Void {
        if (!base) base = exports.base;
        if (!state) state = [];
        ancestorWalk(node, state, visitors, base);
    }

    static private function ancestorWalk(node:Dynamic, st:Dynamic, visitors:Dynamic, base:Dynamic):Void {
        var type = node.type;
        var found = visitors[type];
        if (node != st[st.length - 1]) {
            st = st.slice();
            st.push(node);
        }
        base[type](node, st, ancestorWalk);
        if (found) found(node, st);
    }

    static public function recursive(node:Dynamic, state:Dynamic, funcs:Dynamic, base:Dynamic):Void {
        var visitor = funcs != null ? make(funcs, base) : base;
        recursiveWalk(node, state, visitor);
    }

    static private function recursiveWalk(node:Dynamic, st:Dynamic, visitor:Dynamic):Void {
        var type = node.type;
        visitor[type](node, st, recursiveWalk);
    }

    static public function makeTest(test:Dynamic):Dynamic {
        if (Std.is(test, String)) {
            return function (type:String):Bool {
                return type == test;
            };
        } else if (test == null) {
            return function ():Bool {
                return true;
            };
        } else {
            return test;
        }
    }

    static public function findNodeAt(node:Dynamic, start:Int, end:Int, test:Dynamic, base:Dynamic, state:Dynamic):Dynamic {
        test = makeTest(test);
        if (!base) base = exports.base;
        try {
            findNodeAtWalk(node, state, test, base);
        } catch (e:Found) {
            return e;
        }
        return null;
    }

    static private function findNodeAtWalk(node:Dynamic, st:Dynamic, test:Dynamic, base:Dynamic):Void {
        var type = node.type;
        if ((start == null || node.start <= start) && (end == null || node.end >= end)) base[type](node, st, findNodeAtWalk);
        if (test(type, node) && (start == null || node.start == start) && (end == null || node.end == end)) throw new Found(node, st);
    }

    static public function findNodeAround(node:Dynamic, pos:Int, test:Dynamic, base:Dynamic, state:Dynamic):Dynamic {
        test = makeTest(test);
        if (!base) base = exports.base;
        try {
            findNodeAroundWalk(node, pos, test, base, state);
        } catch (e:Found) {
            return e;
        }
        return null;
    }

    static private function findNodeAroundWalk(node:Dynamic, pos:Int, test:Dynamic, base:Dynamic, st:Dynamic):Void {
        var type = node.type;
        if (node.start > pos || node.end < pos) return;
        base[type](node, st, findNodeAroundWalk);
        if (test(type, node)) throw new Found(node, st);
    }

    static public function findNodeAfter(node:Dynamic, pos:Int, test:Dynamic, base:Dynamic, state:Dynamic):Dynamic {
        test = makeTest(test);
        if (!base) base = exports.base;
        try {
            findNodeAfterWalk(node, pos, test, base, state);
        } catch (e:Found) {
            return e;
        }
        return null;
    }

    static private function findNodeAfterWalk(node:Dynamic, pos:Int, test:Dynamic, base:Dynamic, st:Dynamic):Void {
        if (node.end < pos) return;
        var type = node.type;
        if (node.start >= pos && test(type, node)) throw new Found(node, st);
        base[type](node, st, findNodeAfterWalk);
    }

    static public function findNodeBefore(node:Dynamic, pos:Int, test:Dynamic, base:Dynamic, state:Dynamic):Dynamic {
        test = makeTest(test);
        if (!base) base = exports.base;
        var max:Found = null;
        findNodeBeforeWalk(node, pos, test, base, state, max);
        return max;
    }

    static private function findNodeBeforeWalk(node:Dynamic, pos:Int, test:Dynamic, base:Dynamic, st:Dynamic, max:Found):Void {
        if (node.start > pos) return;
        var type = node.type;
        if (node.end <= pos && (!max || max.node.end < node.end) && test(type, node)) max = new Found(node, st);
        base[type](node, st, findNodeBeforeWalk);
    }

    static public function make(funcs:Dynamic, base:Dynamic):Dynamic {
        if (!base) base = exports.base;
        var visitor = {};
        for (type in base.keys()) visitor[type] = base[type];
        for (type in funcs.keys()) visitor[type] = funcs[type];
        return visitor;
    }

    static public function skipThrough(node:Dynamic, st:Dynamic, c:Dynamic):Void {
        c(node, st);
    }

    static public function ignore(node:Dynamic, st:Dynamic, c:Dynamic):Void {}

    static public var base:StringMap<Dynamic> = new StringMap();

    static public function init():Void {
        base.set("Program", function (node:Dynamic, st:Dynamic, c:Dynamic):Void {
            for (i in 0...node.body.length) c(node.body[i], st, "Statement");
        });
        base.set("BlockStatement", base.get("Program"));
        base.set("Statement", skipThrough);
        base.set("EmptyStatement", ignore);
        base.set("ExpressionStatement", function (node:Dynamic, st:Dynamic, c:Dynamic):Void {
            return c(node.expression, st, "Expression");
        });
        base.set("IfStatement", function (node:Dynamic, st:Dynamic, c:Dynamic):Void {
            c(node.test, st, "Expression");
            c(node.consequent, st, "Statement");
            if (node.alternate != null) c(node.alternate, st, "Statement");
        });
        // ...
    }
}