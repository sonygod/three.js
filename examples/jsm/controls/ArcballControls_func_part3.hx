package three.js.examples.jsm.controls;

class ArcballControls {
    public var mouseActions:Array<Dynamic>;

    public function new() {
        mouseActions = new Array<Dynamic>();
    }

    public function setMouseAction(operation:String, mouse:Int, key:Null<String> = null):Bool {
        var operationInput:Array<String> = ['PAN', 'ROTATE', 'ZOOM', 'FOV'];
        var mouseInput:Array<Dynamic> = [0, 1, 2, 'WHEEL'];
        var keyInput:Array<Dynamic> = ['CTRL', 'SHIFT', null];
        var state:Null<String>;

        if (!operationInput.contains(operation) || !mouseInput.contains(mouse) || !keyInput.contains(key)) {
            return false;
        }

        if (mouse == 'WHEEL' && operation != 'ZOOM' && operation != 'FOV') {
            return false;
        }

        switch (operation) {
            case 'PAN':
                state = STATE.PAN;
            case 'ROTATE':
                state = STATE.ROTATE;
            case 'ZOOM':
                state = STATE.SCALE;
            case 'FOV':
                state = STATE.FOV;
        }

        var action:Dynamic = {
            operation: operation,
            mouse: mouse,
            key: key,
            state: state
        };

        for (i in 0...mouseActions.length) {
            if (mouseActions[i].mouse == action.mouse && mouseActions[i].key == action.key) {
                mouseActions[i] = action;
                return true;
            }
        }

        mouseActions.push(action);
        return true;
    }

    public function unsetMouseAction(mouse:Int, key:Null<String> = null):Bool {
        for (i in 0...mouseActions.length) {
            if (mouseActions[i].mouse == mouse && mouseActions[i].key == key) {
                mouseActions.splice(i, 1);
                return true;
            }
        }
        return false;
    }

    public function getOpFromAction(mouse:Int, key:Null<String> = null):Null<String> {
        for (action in mouseActions) {
            if (action.mouse == mouse && action.key == key) {
                return action.operation;
            }
        }
        if (key != null) {
            for (action in mouseActions) {
                if (action.mouse == mouse && action.key == null) {
                    return action.operation;
                }
            }
        }
        return null;
    }

    public function getOpStateFromAction(mouse:Int, key:Null<String> = null):Null<String> {
        for (action in mouseActions) {
            if (action.mouse == mouse && action.key == key) {
                return action.state;
            }
        }
        if (key != null) {
            for (action in mouseActions) {
                if (action.mouse == mouse && action.key == null) {
                    return action.state;
                }
            }
        }
        return null;
    }

    // ... rest of the methods ...
}