class LutReader {
	static function splitOnSpaceHandleQuotesWithEscapes(str:String, splits:String = ' \t\n\r'):Array<String> {
		var strings:Array<String> = [];
		var quoteType:String = null;
		var escape:Bool = false;
		var s:Array<String> = [];
		for (i in 0...str.length) {
			var c:String = str.charAt(i);
			if (escape) {
				escape = false;
				s.push(c);
			} else {
				if (quoteType != null) {
					if (c == quoteType) {
						quoteType = null;
						strings.push(s.join(""));
						s = [];
					} else if (c == '\\') {
						escape = true;
					} else {
						s.push(c);
					}
				} else {
					if (splits.indexOf(c) != -1) {
						if (s.length > 0) {
							strings.push(s.join(""));
							s = [];
						}
					} else if (c == '"' || c == '\'') {
						if (s.length > 0) {
							s.push(c);
						} else {
							quoteType = c;
						}
					} else {
						s.push(c);
					}
				}
			}
		}
		if (s.length > 0 || strings.length == 0) {
			strings.push(s.join(""));
		}
		return strings;
	}

	static function parseCSP(str:String):Dynamic {
		var data:Array<Float> = [];
		var lut:Dynamic = {
			name: 'unknown',
			type: '1D',
			size: 0,
			data: data,
			min: [0., 0., 0.],
			max: [1., 1., 1.],
		};
		// The rest of the function...
	}

	static function parseCUBE(str:String):Dynamic {
		var data:Array<Float> = [];
		var lut:Dynamic = {
			name: 'unknown',
			type: '1D',
			size: 0,
			data: data,
			min: [0., 0., 0.],
			max: [1., 1., 1.],
		};
		// The rest of the function...
	}

	static function lutTo2D3Drgba8(lut:Dynamic):Dynamic {
		// The rest of the function...
	}

	static function parse(str:String, format:String = 'cube'):Dynamic {
		// The rest of the function...
	}
}