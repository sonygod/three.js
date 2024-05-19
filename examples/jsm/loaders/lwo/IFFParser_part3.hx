package three.js.examples.jm.loaders.lwo;

class Debugger {
    public var active:Bool = false;
    public var depth:Int = 0;
    public var formList:Array<Int> = [];

    public function new() {}

    public function enable():Void {
        active = true;
    }

    public function log():Void {
        if (!active) return;

        var nodeType:String;
        switch (node) {
            case 0:
                nodeType = 'FORM';
                break;
            case 1:
                nodeType = 'CHK';
                break;
            case 2:
                nodeType = 'S-CHK';
                break;
        }

        trace(
            '| '.repeat(depth) + nodeType,
            nodeID,
            '(${offset}) -> (${dataOffset + length})',
            (node == 0 ? ' {' : ''),
            (skipped ? 'SKIPPED' : ''),
            (node == 0 && skipped ? '}' : '')
        );

        if (node == 0 && !skipped) {
            depth += 1;
            formList.push(dataOffset + length);
        }

        skipped = false;
    }

    public function closeForms():Void {
        if (!active) return;

        for (i in formList.length - 1 ... 0) {
            if (offset >= formList[i]) {
                depth -= 1;
                trace('| '.repeat(depth) + '} ');
                formList.splice(formList.length - 1, 1);
            }
        }
    }
}