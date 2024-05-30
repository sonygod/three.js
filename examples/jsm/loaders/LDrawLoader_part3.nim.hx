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

        while (this.currentCharIndex < this.lineLength) {

            this.currentChar = this.line.charAt(this.currentCharIndex);

            if (this.currentChar !== ' ' && this.currentChar !== '\t') {

                return;

            }

            this.currentCharIndex++;

        }

    }

    public function getToken() {

        var pos0 = this.currentCharIndex++;

        // Seek space
        while (this.currentCharIndex < this.lineLength) {

            this.currentChar = this.line.charAt(this.currentCharIndex);

            if (this.currentChar === ' ' || this.currentChar === '\t') {

                break;

            }

            this.currentCharIndex++;

        }

        var pos1 = this.currentCharIndex;

        this.seekNonSpace();

        return this.line.substr(pos0, pos1 - pos0);

    }

    public function getVector() {

        return new Vector3(Std.parseFloat(this.getToken()), Std.parseFloat(this.getToken()), Std.parseFloat(this.getToken()));

    }

    public function getRemainingString() {

        return this.line.substr(this.currentCharIndex, this.lineLength - this.currentCharIndex);

    }

    public function isAtTheEnd() {

        return this.currentCharIndex >= this.lineLength;

    }

    public function setToEnd() {

        this.currentCharIndex = this.lineLength;

    }

    public function getLineNumberString() {

        return this.lineNumber >= 0 ? ' at line ' + this.lineNumber : '';

    }

}