class LineParser {

	public var line:String;
	public var lineLength:Int;
	public var currentCharIndex:Int;
	public var currentChar:String;
	public var lineNumber:Int;

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

			if (this.currentChar != ' ' && this.currentChar != '\t') {

				return;

			}

			this.currentCharIndex++;

		}

	}

	public function getToken():String {

		var pos0 = this.currentCharIndex++;

		// Seek space
		while (this.currentCharIndex < this.lineLength) {

			this.currentChar = this.line.charAt(this.currentCharIndex);

			if (this.currentChar == ' ' || this.currentChar == '\t') {

				break;

			}

			this.currentCharIndex++;

		}

		var pos1 = this.currentCharIndex;

		this.seekNonSpace();

		return this.line.substring(pos0, pos1);

	}

	public function getVector():Vector3 {

		return new Vector3(Std.parseFloat(this.getToken()), Std.parseFloat(this.getToken()), Std.parseFloat(this.getToken()));

	}

	public function getRemainingString():String {

		return this.line.substring(this.currentCharIndex, this.lineLength);

	}

	public function isAtTheEnd():Bool {

		return this.currentCharIndex >= this.lineLength;

	}

	public function setToEnd() {

		this.currentCharIndex = this.lineLength;

	}

	public function getLineNumberString():String {

		return this.lineNumber >= 0 ? ' at line ' + this.lineNumber : '';

	}

}