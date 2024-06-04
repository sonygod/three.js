import js.html.Element;
import js.html.Canvas;
import js.html.Table;
import js.html.Span;
import js.html.Document;
import js.html.Window;
import js.html.ImageData;
import js.html.CanvasRenderingContext2D;

class AsciiEffect {

  public var renderer:Dynamic;
  public var charSet:String = ' .:-=+*#%@';
  public var options:Dynamic;
  public var domElement:Element;

  public function new(renderer:Dynamic, charSet:String = ' .:-=+*#%@', options:Dynamic = {}) {
    this.renderer = renderer;
    this.charSet = charSet;
    this.options = options;

    // ' .,:;=|iI+hHOE#`$';
    // darker bolder character set from https://github.com/saw/Canvas-ASCII-Art/
    // ' .\'`^",:;Il!i~+_-?][}{1)(|/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$'.split('');

    // Some ASCII settings

    var fResolution = options.resolution || 0.15; // Higher for more details
    var iScale = options.scale || 1;
    var bColor = options.color || false; // nice but slows down rendering!
    var bAlpha = options.alpha || false; // Transparency
    var bBlock = options.block || false; // blocked characters. like good O dos
    var bInvert = options.invert || false; // black is white, white is black
    var strResolution = options.strResolution || 'low';

    var width:Int, height:Int;

    domElement = Document.window.document.createElement('div');
    domElement.style.cursor = 'default';

    var oAscii = Document.window.document.createElement('table');
    domElement.appendChild(oAscii);

    var iWidth:Int, iHeight:Int;
    var oImg:Dynamic;

    this.setSize = function(w:Int, h:Int) {
      width = w;
      height = h;

      renderer.setSize(w, h);

      initAsciiSize();
    };

    this.render = function(scene:Dynamic, camera:Dynamic) {
      renderer.render(scene, camera);
      asciifyImage(oAscii);
    };

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

    var aDefaultCharList = ( ' .,:;i1tfLCG08@' ).split('');
    var aDefaultColorCharList = ( ' CGO08@' ).split('');
    var strFont = 'courier new, monospace';

    var oCanvasImg = renderer.domElement;

    var oCanvas = Document.window.document.createElement('canvas');
    if (!oCanvas.getContext) {
      return;
    }

    var oCtx = oCanvas.getContext('2d');
    if (!oCtx.getImageData) {
      return;
    }

    var aCharList = (bColor ? aDefaultColorCharList : aDefaultCharList);
    if (charSet != null) aCharList = charSet.split('');

    // Setup dom

    var fFontSize = (2 / fResolution) * iScale;
    var fLineHeight = (2 / fResolution) * iScale;

    // adjust letter-spacing for all combinations of scale and resolution to get it to fit the image width.

    var fLetterSpacing:Float = 0;

    if (strResolution == 'low') {
      switch (iScale) {
        case 1: fLetterSpacing = -1; break;
        case 2:
        case 3: fLetterSpacing = -2.1; break;
        case 4: fLetterSpacing = -3.1; break;
        case 5: fLetterSpacing = -4.15; break;
      }
    }

    if (strResolution == 'medium') {
      switch (iScale) {
        case 1: fLetterSpacing = 0; break;
        case 2: fLetterSpacing = -1; break;
        case 3: fLetterSpacing = -1.04; break;
        case 4:
        case 5: fLetterSpacing = -2.1; break;
      }
    }

    if (strResolution == 'high') {
      switch (iScale) {
        case 1:
        case 2: fLetterSpacing = 0; break;
        case 3:
        case 4:
        case 5: fLetterSpacing = -1; break;
      }
    }

    // can't get a span or div to flow like an img element, but a table works?

    // convert img element to ascii

    function asciifyImage(oAscii:Table) {
      oCtx.clearRect(0, 0, iWidth, iHeight);
      oCtx.drawImage(oCanvasImg, 0, 0, iWidth, iHeight);
      var oImgData = oCtx.getImageData(0, 0, iWidth, iHeight).data;

      // Coloring loop starts now
      var strChars:String = '';

      // console.time('rendering');

      for (y in 0...iHeight) {
        for (x in 0...iWidth) {
          var iOffset = (y * iWidth + x) * 4;

          var iRed = oImgData[iOffset];
          var iGreen = oImgData[iOffset + 1];
          var iBlue = oImgData[iOffset + 2];
          var iAlpha = oImgData[iOffset + 3];
          var iCharIdx:Int;

          var fBrightness:Float;

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

          if (strThisChar == null || strThisChar == ' ')
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

      oAscii.innerHTML = `<tr><td style="display:block;width:${width}px;height:${height}px;overflow:hidden">${strChars}</td></tr>`;

      // console.timeEnd('rendering');

      // return oAscii;
    }
  }
}