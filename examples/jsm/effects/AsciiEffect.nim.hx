/**
 * Ascii generation is based on https://github.com/hassadee/jsascii/blob/master/jsascii.js
 *
 * 16 April 2012 - @blurspline
 */

class AsciiEffect {

	public var renderer:Renderer;
	public var charSet:String = ' .:-=+*#%@';
	public var options:Dynamic = new Dynamic();

	public function new(renderer:Renderer, ?charSet:String, ?options:Dynamic) {

		if (charSet != null) this.charSet = charSet;
		if (options != null) this.options = options;

		// Some ASCII settings

		var fResolution = (this.options.resolution != null) ? this.options.resolution : 0.15; // Higher for more details
		var iScale = (this.options.scale != null) ? this.options.scale : 1;
		var bColor = (this.options.color != null) ? this.options.color : false; // nice but slows down rendering!
		var bAlpha = (this.options.alpha != null) ? this.options.alpha : false; // Transparency
		var bBlock = (this.options.block != null) ? this.options.block : false; // blocked characters. like good O dos
		var bInvert = (this.options.invert != null) ? this.options.invert : false; // black is white, white is black
		var strResolution = (this.options.strResolution != null) ? this.options.strResolution : 'low';

		var width:Int;
		var height:Int;

		var domElement = js.Browser.document.createElement('div');
		domElement.style.cursor = 'default';

		var oAscii = js.Browser.document.createElement('table');
		domElement.appendChild(oAscii);

		var iWidth:Int;
		var iHeight:Int;
		var oImg:Dynamic;

		this.setSize = function(w:Int, h:Int) {

			width = w;
			height = h;

			renderer.setSize(w, h);

			initAsciiSize();

		};

		this.render = function(scene:Scene, camera:Camera) {

			renderer.render(scene, camera);
			asciifyImage(oAscii);

		};

		this.domElement = domElement;

		// Throw in ascii library from https://github.com/hassadee/jsascii/blob/master/jsascii.js (MIT License)

		function initAsciiSize() {

			iWidth = Math.floor(width * fResolution);
			iHeight = Math.floor(height * fResolution);

			oCanvas.width = iWidth;
			oCanvas.height = iHeight;
			// oCanvas.style.display = "none";
			// oCanvas.style.width = iWidth;
			// oCanvas.style.height = iHeight;

			oImg = renderer.domElement;

			if (oImg.style.backgroundColor != null) {

				oAscii.rows[0].cells[0].style.backgroundColor = oImg.style.backgroundColor;
				oAscii.rows[0].cells[0].style.color = oImg.style.color;

			}

			oAscii.cellSpacing = 0;
			oAscii.cellPadding = 0;

			var oStyle = oAscii.style;
			oStyle.whiteSpace = 'pre';
			oStyle.margin = '0px';
			oStyle.padding = '0px';
			oStyle.letterSpacing = fLetterSpacing + 'px';
			oStyle.fontFamily = strFont;
			oStyle.fontSize = fFontSize + 'px';
			oStyle.lineHeight = fLineHeight + 'px';
			oStyle.textAlign = 'left';
			oStyle.textDecoration = 'none';

		}

		var aDefaultCharList = ('.,:;i1tfLCG08@').split('');
		var aDefaultColorCharList = ('CGO08@').split('');
		var strFont = 'courier new, monospace';

		var oCanvasImg = renderer.domElement;

		var oCanvas = js.Browser.document.createElement('canvas');
		if (!oCanvas.getContext) {

			return;

		}

		var oCtx = oCanvas.getContext('2d');
		if (!oCtx.getImageData) {

			return;

		}

		var aCharList = (bColor ? aDefaultColorCharList : aDefaultCharList);

		if (charSet != null) aCharList = charSet;

		// Setup dom

		var fFontSize = (2 / fResolution) * iScale;
		var fLineHeight = (2 / fResolution) * iScale;

		// adjust letter-spacing for all combinations of scale and resolution to get it to fit the image width.

		var fLetterSpacing = 0;

		if (strResolution == 'low') {

			switch (iScale) {

				case 1:
					fLetterSpacing = -1;
					break;
				case 2:
				case 3:
					fLetterSpacing = -2.1;
					break;
				case 4:
					fLetterSpacing = -3.1;
					break;
				case 5:
					fLetterSpacing = -4.15;
					break;

			}

		}

		if (strResolution == 'medium') {

			switch (iScale) {

				case 1:
					fLetterSpacing = 0;
					break;
				case 2:
					fLetterSpacing = -1;
					break;
				case 3:
					fLetterSpacing = -1.04;
					break;
				case 4:
				case 5:
					fLetterSpacing = -2.1;
					break;

			}

		}

		if (strResolution == 'high') {

			switch (iScale) {

				case 1:
				case 2:
					fLetterSpacing = 0;
					break;
				case 3:
				case 4:
				case 5:
					fLetterSpacing = -1;
					break;

			}

		}

		// convert img element to ascii

		function asciifyImage(oAscii:Dynamic) {

			oCtx.clearRect(0, 0, iWidth, iHeight);
			oCtx.drawImage(oCanvasImg, 0, 0, iWidth, iHeight);
			var oImgData = oCtx.getImageData(0, 0, iWidth, iHeight).data;

			// Coloring loop starts now
			var strChars = '';

			// console.time('rendering');

			for (y in 0...iHeight) {

				for (x in 0...iWidth) {

					var iOffset = (y * iWidth + x) * 4;

					var iRed = oImgData[iOffset];
					var iGreen = oImgData[iOffset + 1];
					var iBlue = oImgData[iOffset + 2];
					var iAlpha = oImgData[iOffset + 3];
					var iCharIdx;

					var fBrightness;

					fBrightness = (0.3 * iRed + 0.59 * iGreen + 0.11 * iBlue) / 255;
					// fBrightness = (0.3*iRed + 0.5*iGreen + 0.3*iBlue) / 255;

					if (iAlpha == 0) {

						// should calculate alpha instead, but quick hack :)
						//fBrightness *= (iAlpha / 255);
						fBrightness = 1;

					}

					iCharIdx = Math.floor((1 - fBrightness) * (aCharList.length - 1));

					if (bInvert) {

						iCharIdx = aCharList.length - iCharIdx - 1;

					}

					// good for debugging
					//fBrightness = Math.floor(fBrightness * 10);
					//strThisChar = fBrightness;

					var strThisChar = aCharList[iCharIdx];

					if (strThisChar === undefined || strThisChar == ' ')
						strThisChar = '&nbsp;';

					if (bColor) {

						strChars += '<span style=\''
							+ 'color:rgb(' + iRed + ',' + iGreen + ',' + iBlue + ');'
							+ (bBlock ? 'background-color:rgb(' + iRed + ',' + iGreen + ',' + iBlue + ');' : '')
							+ (bAlpha ? 'opacity:' + (iAlpha / 255) + ';' : '')
							+ '\'>' + strThisChar + '</span>';

					} else {

						strChars += strThisChar;

					}

				}

				strChars += '<br/>';

			}

			oAscii.innerHTML = '<tr><td style="display:block;width:' + width + 'px;height:' + height + 'px;overflow:hidden">' + strChars + '</td></tr>';

			// console.timeEnd('rendering');

			// return oAscii;

		}

	}

}