package three.js.examples.jsm.loaders;

class LineParser {
    var line:String;
    var lineLength:Int;
    var currentCharIndex:Int;
    var currentChar:String;
    var lineNumber:Int;

    public function new(line:String, lineNumber:Int) {
        this.line = line;
        this.lineLength = line.length;
        this.currentCharIndex = 0;
        this.currentChar = ' ';
        this.lineNumber = lineNumber;
    }

    public function seekNonSpace() {
        while (currentCharIndex < lineLength) {
            currentChar = line.charAt(currentCharIndex);

            if (currentChar != ' ' && currentChar != '\t') {
                return;
            }

            currentCharIndex++;
        }
    }

    public function getToken():String {
        var pos0:Int = currentCharIndex++;
        while (currentCharIndex < lineLength) {
            currentChar = line.charAt(currentCharIndex);

            if (currentChar == ' ' || currentChar == '\t') {
                break;
            }

            currentCharIndex++;
        }

        var pos1:Int = currentCharIndex;
        seekNonSpace();
        return line.substring(pos0, pos1);
    }

    public function getVector():Vector3 {
        return new Vector3(Std.parseFloat(getToken()), Std.parseFloat(getToken()), Std.parseFloat(getToken()));
    }

    public function getRemainingString():String {
        return line.substring(currentCharIndex, lineLength);
    }

    public function isAtTheEnd():Bool {
        return currentCharIndex >= lineLength;
    }

    public function setToEnd() {
        currentCharIndex = lineLength;
    }

    public function getLineNumberString():String {
        return lineNumber >= 0 ? ' at line ' + lineNumber : '';
    }
}