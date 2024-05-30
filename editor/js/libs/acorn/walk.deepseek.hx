class Found {
    public var node:Dynamic;
    public var state:Dynamic;

    public function new(node:Dynamic, state:Dynamic) {
        this.node = node;
        this.state = state;
    }
}

class Walk {
    static var base:Dynamic;

    static function simple(node:Dynamic, visitors:Dynamic, base:Dynamic, state:Dynamic) {
        if (!base) base = Walk.base;
        (function c(node:Dynamic, st:Dynamic, override:Dynamic) {
            var type = override || node.type,
                found = visitors[type];
            base[type](node, st, c);
            if (found) found(node, st);
        })(node, state);
    }

    static function ancestor(node:Dynamic, visitors:Dynamic, base:Dynamic, state:Dynamic) {
        if (!base) base = Walk.base;
        if (!state) state = [];
        (function c(node:Dynamic, st:Dynamic, override:Dynamic) {
            var type = override || node.type,
                found = visitors[type];
            if (node != st[st.length - 1]) {
                st = st.slice();
                st.push(node);
            }
            base[type](node, st, c);
            if (found) found(node, st);
        })(node, state);
    }

    static function recursive(node:Dynamic, state:Dynamic, funcs:Dynamic, base:Dynamic) {
        var visitor = funcs ? Walk.make(funcs, base) : base;
        (function c(node:Dynamic, st:Dynamic, override:Dynamic) {
            visitor[override || node.type](node, st, c);
        })(node, state);
    }

    static function makeTest(test:Dynamic) {
        if (typeof test == "String") {
            return function (type:Dynamic) {
                return type == test;
            };
        } else if (!test) {
            return function () {
                return true;
            };
        } else {
            return test;
        }
    }

    static function findNodeAt(node:Dynamic, start:Dynamic, end:Dynamic, test:Dynamic, base:Dynamic, state:Dynamic) {
        test = Walk.makeTest(test);
        if (!base) base = Walk.base;
        try {
            (function c(node:Dynamic, st:Dynamic, override:Dynamic) {
                var type = override || node.type;
                if ((start == null || node.start <= start) && (end == null || node.end >= end)) base[type](node, st, c);
                if (test(type, node) && (start == null || node.start == start) && (end == null || node.end == end)) throw new Found(node, st);
            })(node, state);
        } catch (e:Dynamic) {
            if (e instanceof Found) {
                return e;
            }
            throw e;
        }
    }

    static function findNodeAround(node:Dynamic, pos:Dynamic, test:Dynamic, base:Dynamic, state:Dynamic) {
        test = Walk.makeTest(test);
        if (!base) base = Walk.base;
        try {
            (function c(node:Dynamic, st:Dynamic, override:Dynamic) {
                var type = override || node.type;
                if (node.start > pos || node.end < pos) {
                    return;
                }
                base[type](node, st, c);
                if (test(type, node)) throw new Found(node, st);
            })(node, state);
        } catch (e:Dynamic) {
            if (e instanceof Found) {
                return e;
            }
            throw e;
        }
    }

    static function findNodeAfter(node:Dynamic, pos:Dynamic, test:Dynamic, base:Dynamic, state:Dynamic) {
        test = Walk.makeTest(test);
        if (!base) base = Walk.base;
        try {
            (function c(node:Dynamic, st:Dynamic, override:Dynamic) {
                if (node.end < pos) {
                    return;
                }
                var type = override || node.type;
                if (node.start >= pos && test(type, node)) throw new Found(node, st);
                base[type](node, st, c);
            })(node, state);
        } catch (e:Dynamic) {
            if (e instanceof Found) {
                return e;
            }
            throw e;
        }
    }

    static function findNodeBefore(node:Dynamic, pos:Dynamic, test:Dynamic, base:Dynamic, state:Dynamic) {
        test = Walk.makeTest(test);
        if (!base) base = Walk.base;
        var max:Dynamic = undefined;
        (function c(node:Dynamic, st:Dynamic, override:Dynamic) {
            if (node.start > pos) {
                return;
            }
            var type = override || node.type;
            if (node.end <= pos && (!max || max.node.end < node.end) && test(type, node)) max = new Found(node, st);
            base[type](node, st, c);
        })(node, state);
        return max;
    }

    static function make(funcs:Dynamic, base:Dynamic) {
        if (!base) base = Walk.base;
        var visitor:Dynamic = {};
        for (var type in base) visitor[type] = base[type];
        for (var type in funcs) visitor[type] = funcs[type];
        return visitor;
    }

    static function skipThrough(node:Dynamic, st:Dynamic, c:Dynamic) {
        c(node, st);
    }

    static function ignore(node:Dynamic, st:Dynamic, c:Dynamic) {}

    static var base:Dynamic = {
        Program: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            for (var i = 0; i < node.body.length; ++i) {
                c(node.body[i], st, "Statement");
            }
        },
        BlockStatement: Walk.base.Program,
        Statement: Walk.skipThrough,
        EmptyStatement: Walk.ignore,
        ExpressionStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node.expression, st, "Expression");
        },
        ParenthesizedExpression: Walk.ExpressionStatement,
        IfStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.test, st, "Expression");
            c(node.consequent, st, "Statement");
            if (node.alternate) c(node.alternate, st, "Statement");
        },
        LabeledStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node.body, st, "Statement");
        },
        BreakStatement: Walk.ignore,
        ContinueStatement: Walk.ignore,
        WithStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.object, st, "Expression");
            c(node.body, st, "Statement");
        },
        SwitchStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.discriminant, st, "Expression");
            for (var i = 0; i < node.cases.length; ++i) {
                var cs = node.cases[i];
                if (cs.test) c(cs.test, st, "Expression");
                for (var j = 0; j < cs.consequent.length; ++j) {
                    c(cs.consequent[j], st, "Statement");
                }
            }
        },
        ReturnStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.argument) c(node.argument, st, "Expression");
        },
        YieldExpression: Walk.ReturnStatement,
        ThrowStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node.argument, st, "Expression");
        },
        SpreadElement: Walk.ThrowStatement,
        RestElement: Walk.ThrowStatement,
        TryStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.block, st, "Statement");
            if (node.handler) c(node.handler.body, st, "ScopeBody");
            if (node.finalizer) c(node.finalizer, st, "Statement");
        },
        WhileStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.test, st, "Expression");
            c(node.body, st, "Statement");
        },
        DoWhileStatement: Walk.WhileStatement,
        ForStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.init) c(node.init, st, "ForInit");
            if (node.test) c(node.test, st, "Expression");
            if (node.update) c(node.update, st, "Expression");
            c(node.body, st, "Statement");
        },
        ForInStatement: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.left, st, "ForInit");
            c(node.right, st, "Expression");
            c(node.body, st, "Statement");
        },
        ForOfStatement: Walk.ForInStatement,
        ForInit: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.type == "VariableDeclaration") c(node, st);
            else c(node, st, "Expression");
        },
        DebuggerStatement: Walk.ignore,
        FunctionDeclaration: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node, st, "Function");
        },
        VariableDeclaration: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            for (var i = 0; i < node.declarations.length; ++i) {
                var decl = node.declarations[i];
                if (decl.init) c(decl.init, st, "Expression");
            }
        },
        Function: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node.body, st, "ScopeBody");
        },
        ScopeBody: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node, st, "Statement");
        },
        Expression: Walk.skipThrough,
        ThisExpression: Walk.ignore,
        Super: Walk.ignore,
        MetaProperty: Walk.ignore,
        ArrayExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            for (var i = 0; i < node.elements.length; ++i) {
                var elt = node.elements[i];
                if (elt) c(elt, st, "Expression");
            }
        },
        ArrayPattern: Walk.ArrayExpression,
        ObjectExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            for (var i = 0; i < node.properties.length; ++i) {
                c(node.properties[i], st);
            }
        },
        ObjectPattern: Walk.ObjectExpression,
        FunctionExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node, st, "Function");
        },
        ArrowFunctionExpression: Walk.FunctionExpression,
        SequenceExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            for (var i = 0; i < node.expressions.length; ++i) {
                c(node.expressions[i], st, "Expression");
            }
        },
        UnaryExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.argument, st, "Expression");
        },
        UpdateExpression: Walk.UnaryExpression,
        BinaryExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.left, st, "Expression");
            c(node.right, st, "Expression");
        },
        AssignmentExpression: Walk.BinaryExpression,
        AssignmentPattern: Walk.BinaryExpression,
        LogicalExpression: Walk.BinaryExpression,
        ConditionalExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.test, st, "Expression");
            c(node.consequent, st, "Expression");
            c(node.alternate, st, "Expression");
        },
        NewExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.callee, st, "Expression");
            if (node.arguments) for (var i = 0; i < node.arguments.length; ++i) {
                c(node.arguments[i], st, "Expression");
            }
        },
        CallExpression: Walk.NewExpression,
        MemberExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.object, st, "Expression");
            if (node.computed) c(node.property, st, "Expression");
        },
        ExportDeclaration: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node.declaration, st);
        },
        ImportDeclaration: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            for (var i = 0; i < node.specifiers.length; i++) {
                c(node.specifiers[i], st);
            }
        },
        ImportSpecifier: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.computed) c(node.local, st, "Expression");
        },
        ImportBatchSpecifier: Walk.ImportSpecifier,
        Identifier: Walk.ignore,
        Literal: Walk.ignore,
        TaggedTemplateExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.tag, st, "Expression");
            c(node.quasi, st);
        },
        ClassDeclaration: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.superClass) c(node.superClass, st, "Expression");
            for (var i = 0; i < node.body.body.length; i++) {
                c(node.body.body[i], st);
            }
        },
        ClassExpression: Walk.ClassDeclaration,
        MethodDefinition: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.computed) c(node.key, st, "Expression");
            c(node.value, st, "Expression");
        },
        Property: Walk.MethodDefinition,
        ComprehensionExpression: function (node:Dynamic, st:Dynamic, c:Dynamic) {
            for (var i = 0; i < node.blocks.length; i++) {
                c(node.blocks[i].right, st, "Expression");
            }
            c(node.body, st, "Expression");
        }
    };
}