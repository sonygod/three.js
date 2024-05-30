package js;

import js.Node;

class Found {
    public var node:Node;
    public var state:Array<Node>;
    public function new(node:Node, state:Array<Node>) {
        this.node = node;
        this.state = state;
    }
}

class Walk {
    public static function simple(node:Node, visitors:Dynamic, ?base:Dynamic, ?state:Dynamic) {
        if (base == null) base = Walk.base;
        node.accept(base, state, null);
    }

    public static function ancestor(node:Node, visitors:Dynamic, ?base:Dynamic, ?state:Dynamic) {
        if (base == null) base = Walk.base;
        if (state == null) state = [];
        node.accept(base, state, null);
    }

    public static function recursive(node:Node, state:Dynamic, ?funcs:Dynamic, ?base:Dynamic) {
        if (base == null) base = Walk.base;
        if (funcs == null) funcs = {};
        var visitor = { $merge(base, funcs) };
        node.accept(visitor, state, null);
    }

    public static function findNodeAt(node:Node, ?start:Int, ?end:Int, ?test:Dynamic, ?base:Dynamic, ?state:Dynamic) {
        if (test == null) test = { _: function(_) return true; };
        if (base == null) base = Walk.base;
        try {
            node.accept(base, state, { $bind(test) });
        } catch(e:Found) {
            return e;
        }
    }

    public static function findNodeAround(node:Node, pos:Int, ?test:Dynamic, ?base:Dynamic, ?state:Dynamic) {
        if (test == null) test = { _: function(_) return true; };
        if (base == null) base = Walk.base;
        try {
            node.accept(base, state, { $bind(test) });
        } catch(e:Found) {
            return e;
        }
    }

    public static function findNodeAfter(node:Node, pos:Int, ?test:Dynamic, ?base:Dynamic, ?state:Dynamic) {
        if (test == null) test = { _: function(_) return true; };
        if (base == null) base = Walk.base;
        try {
            node.accept(base, state, { $bind(test) });
        } catch(e:Found) {
            return e;
        }
    }

    public static function findNodeBefore(node:Node, pos:Int, ?test:Dynamic, ?base:Dynamic, ?state:Dynamic) {
        if (test == null) test = { _: function(_) return true; };
        if (base == null) base = Walk.base;
        var max:Found = null;
        node.accept(base, state, { $bind(test) });
        return max;
    }

    public static function make(?funcs:Dynamic, ?base:Dynamic) {
        if (base == null) base = Walk.base;
        var visitor = { $copy(base) };
        if (funcs != null) {
            $iter(funcs, function(type, func) {
                visitor[type] = func;
            });
        }
        return visitor;
    }

    public static function skipThrough(node:Node, st:Dynamic, c:Dynamic) {
        c(node, st);
    }

    public static function ignore(node:Node, st:Dynamic, c:Dynamic) {
    }

    public static var base:Dynamic = {
        Program: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.body.length) {
                c(node.body[i], st, "Statement");
            }
        },
        BlockStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.body.length) {
                c(node.body[i], st, "Statement");
            }
        },
        Statement: Walk.skipThrough,
        EmptyStatement: Walk.ignore,
        ExpressionStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.expression, st, "Expression");
        },
        ParenthesizedExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.expression, st, "Expression");
        },
        IfStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.test, st, "Expression");
            c(node.consequent, st, "Statement");
            if (node.alternate != null) c(node.alternate, st, "Statement");
        },
        LabeledStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.body, st, "Statement");
        },
        BreakStatement: Walk.ignore,
        ContinueStatement: Walk.ignore,
        WithStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.object, st, "Expression");
            c(node.body, st, "Statement");
        },
        SwitchStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.discriminant, st, "Expression");
            for (i in 0...node.cases.length) {
                var cs = node.cases[i];
                if (cs.test != null) c(cs.test, st, "Expression");
                for (j in 0...cs.consequent.length) {
                    c(cs.consequent[j], st, "Statement");
                }
            }
        },
        ReturnStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            if (node.argument != null) c(node.argument, st, "Expression");
        },
        YieldExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            if (node.argument != null) c(node.argument, st, "Expression");
        },
        ThrowStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.argument, st, "Expression");
        },
        SpreadElement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.argument, st, "Expression");
        },
        RestElement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.argument, st, "Expression");
        },
        TryStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.block, st, "Statement");
            if (node.handler != null) c(node.handler.body, st, "ScopeBody");
            if (node.finalizer != null) c(node.finalizer, st, "Statement");
        },
        WhileStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.test, st, "Expression");
            c(node.body, st, "Statement");
        },
        DoWhileStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.test, st, "Expression");
            c(node.body, st, "Statement");
        },
        ForStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            if (node.init != null) c(node.init, st, "ForInit");
            if (node.test != null) c(node.test, st, "Expression");
            if (node.update != null) c(node.update, st, "Expression");
            c(node.body, st, "Statement");
        },
        ForInStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.left, st, "ForInit");
            c(node.right, st, "Expression");
            c(node.body, st, "Statement");
        },
        ForOfStatement: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.left, st, "ForInit");
            c(node.right, st, "Expression");
            c(node.body, st, "Statement");
        },
        ForInit: function(node:Node, st:Dynamic, c:Dynamic) {
            if (node.nodeType == Node.VARIABLE_DECLARATION) c(node, st);
            else c(node, st, "Expression");
        },
        DebuggerStatement: Walk.ignore,
        FunctionDeclaration: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node, st, "Function");
        },
        VariableDeclaration: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.declarations.length) {
                var decl = node.declarations[i];
                if (decl.init != null) c(decl.init, st, "Expression");
            }
        },
        Function: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.body, st, "ScopeBody");
        },
        ScopeBody: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node, st, "Statement");
        },
        Expression: Walk.skipThrough,
        ThisExpression: Walk.ignore,
        Super: Walk.ignore,
        MetaProperty: Walk.ignore,
        ArrayExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.elements.length) {
                var elt = node.elements[i];
                if (elt != null) c(elt, st, "Expression");
            }
        },
        ArrayPattern: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.elements.length) {
                var elt = node.elements[i];
                if (elt != null) c(elt, st, "Expression");
            }
        },
        ObjectExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.properties.length) {
                c(node.properties[i], st);
            }
        },
        ObjectPattern: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.properties.length) {
                c(node.properties[i], st);
            }
        },
        FunctionExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.body, st, "ScopeBody");
        },
        ArrowFunctionExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.body, st, "ScopeBody");
        },
        SequenceExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.expressions.length) {
                c(node.expressions[i], st, "Expression");
            }
        },
        TemplateLiteral: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.expressions.length) {
                c(node.expressions[i], st, "Expression");
            }
        },
        UnaryExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.argument, st, "Expression");
        },
        UpdateExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.argument, st, "Expression");
        },
        BinaryExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.left, st, "Expression");
            c(node.right, st, "Expression");
        },
        AssignmentExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.left, st, "Expression");
            c(node.right, st, "Expression");
        },
        AssignmentPattern: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.left, st, "Expression");
            c(node.right, st, "Expression");
        },
        LogicalExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.left, st, "Expression");
            c(node.right, st, "Expression");
        },
        ConditionalExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.test, st, "Expression");
            c(node.consequent, st, "Expression");
            c(node.alternate, st, "Expression");
        },
        NewExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.callee, st, "Expression");
            if (node.arguments != null) for (i in 0...node.arguments.length) {
                c(node.arguments[i], st, "Expression");
            }
        },
        CallExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.callee, st, "Expression");
            if (node.arguments != null) for (i in 0...node.arguments.length) {
                c(node.arguments[i], st, "Expression");
            }
        },
        MemberExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.object, st, "Expression");
            if (node.computed) c(node.property, st, "Expression");
        },
        ExportDeclaration: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.declaration, st);
        },
        ImportDeclaration: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.specifiers.length) {
                c(node.specifiers[i], st);
            }
        },
        ImportSpecifier: Walk.ignore,
        ImportBatchSpecifier: Walk.ignore,
        Identifier: Walk.ignore,
        Literal: Walk.ignore,
        TaggedTemplateExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            c(node.tag, st, "Expression");
            c(node.quasi, st);
        },
        ClassDeclaration: function(node:Node, st:Dynamic, c:Dynamic) {
            if (node.superClass != null) c(node.superClass, st, "Expression");
            for (i in 0...node.body.body.length) {
                c(node.body.body[i], st);
            }
        },
        ClassExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            if (node.superClass != null) c(node.superClass, st, "Expression");
            for (i in 0...node.body.body.length) {
                c(node.body.body[i], st);
            }
        },
        MethodDefinition: function(node:Node, st:Dynamic, c:Dynamic) {
            if (node.computed) c(node.key, st, "Expression");
            c(node.value, st, "Expression");
        },
        Property: function(node:Node, st:Dynamic, c:Dynamic) {
            if (node.computed) c(node.key, st, "Expression");
            c(node.value, st, "Expression");
        },
        ComprehensionExpression: function(node:Node, st:Dynamic, c:Dynamic) {
            for (i in 0...node.blocks.length) {
                c(node.blocks[i].right, st, "Expression");
            }
            c(node.body, st, "Expression");
        }
    }
}