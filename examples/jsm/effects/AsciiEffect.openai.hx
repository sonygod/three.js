package three.js.examples.jsm.effects;

class AsciiEffect {
  private var renderer:js.html.CanvasRenderer;
  private var charSet:String;
  private var options:Dynamic;
  private var domElement:js.html.DivElement;
  private var asciiTable:js.html.TableElement;
  private var oCanvas:js.html.CanvasElement;
  private var oCtx:js.html.CanvasRenderingContext2D;
  private var oImg:js.html.ImgElement;
  private var width:Int;
  private var height:Int;
  private var iWidth:Int;
  private var iHeight:Int;
  private var fResolution:Float;
  private var iScale:Int;
  private var bColor:Bool;
  private var bAlpha:Bool;
  private var bBlock:Bool;
  private var bInvert:Bool;
  private var strResolution:String;
  private var strFont:String;
  private var fFontSize:Float;
  private var fLineHeight:Float;
  private var fLetterSpacing:Float;
  private var aCharList:Array<String>;

  public function new(renderer:js.html.CanvasRenderer, charSet:String = ' .:-=+*#%@', options:Dynamic = {}) {
    this.renderer = renderer;
    this.charSet = charSet;
    this.options = options;

    fResolution = options.resolution != null ? options.resolution : 0.15;
    iScale = options.scale != null ? options.scale : 1;
    bColor = options.color != null ? options.color : false;
    bAlpha = options.alpha != null ? options.alpha : false;
    bBlock = options.block != null ? options.block : false;
    bInvert = options.invert != null ? options.invert : false;
    strResolution = options.strResolution != null ? options.strResolution : 'low';

    width = 0;
    height = 0;

    domElement = js.Browser.document.createElement("div");
    domElement.style.cursor = "default";

    asciiTable = js.Browser.document.createElement("table");
    domElement.appendChild(asciiTable);

    oCanvas = js.Browser.document.createElement("canvas");
    oCtx = oCanvas.getContext("2d");

    if (oCtx == null) return;

    oImg = renderer.domElement;

    strFont = 'courier new, monospace';

    aCharList = bColor ? ['C', 'G', 'O', '8', '@'] : ['.', ',', ';', 'i', '1', 't', 'f', 'L', 'C', 'G', '0', '8', '@'];

    if (charSet != null) aCharList = charSet.split('');

    fFontSize = (2 / fResolution) * iScale;
    fLineHeight = (2 / fResolution) * iScale;

    switch (strResolution) {
      case 'low':
        switch (iScale) {
          case 1: fLetterSpacing = -1;
          case 2:
          case 3: fLetterSpacing = -2.1;
          case 4: fLetterSpacing = -3.1;
          case 5: fLetterSpacing = -4.15;
        }
      case 'medium':
        switch (iScale) {
          case 1: fLetterSpacing = 0;
          case 2: fLetterSpacing = -1;
          case 3: fLetterSpacing = -1.04;
          case 4:
          case 5: fLetterSpacing = -2.1;
        }
      case 'high':
        switch (iScale) {
          case 1:
          case 2: fLetterSpacing = 0;
          case 3:
          case 4:
          case 5: fLetterSpacing = -1;
        }
    }

    initAsciiSize();

    this.domElement = domElement;
  }

  public function setSize(w:Int, h:Int):Void {
    width = w;
    height = h;
    renderer.setSize(w, h);
    initAsciiSize();
  }

  public function render(scene:Dynamic, camera:Dynamic):Void {
    renderer.render(scene, camera);
    asciifyImage(asciiTable);
  }

  private function initAsciiSize():Void {
    iWidth = Math.floor(width * fResolution);
    iHeight = Math.floor(height * fResolution);

    oCanvas.width = iWidth;
    oCanvas.height = iHeight;

    oImg = renderer.domElement;

    if (oImg.style.backgroundColor != null) {
      asciiTable.rows[0].cells[0].style.backgroundColor = oImg.style.backgroundColor;
      asciiTable.rows[0].cells[0].style.color = oImg.style.color;
    }

    asciiTable.cellSpacing = 0;
    asciiTable.cellPadding = 0;

    var oStyle:js.html.Style = asciiTable.style;
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

  private function asciifyImage(oAscii:js.html.TableElement):Void {
    oCtx.clearRect(0, 0, iWidth, iHeight);
    oCtx.drawImage(oImg, 0, 0, iWidth, iHeight);
    var oImgData:js.html.ImageData = oCtx.getImageData(0, 0, iWidth, iHeight).data;
    var strChars:String = '';

    for (y in 0...iHeight) {
      for (x in 0...iWidth) {
        var iOffset:Int = (y * iWidth + x) * 4;
        var iRed:Int = oImgData[iOffset];
        var iGreen:Int = oImgData[iOffset + 1];
        var iBlue:Int = oImgData[iOffset + 2];
        var iAlpha:Int = oImgData[iOffset + 3];
        var iCharIdx:Int;

        var fBrightness:Float = (0.3 * iRed + 0.59 * iGreen + 0.11 * iBlue) / 255;

        if (iAlpha == 0) {
          fBrightness = 1;
        }

        iCharIdx = Math.floor((1 - fBrightness) * (aCharList.length - 1));

        if (bInvert) {
          iCharIdx = aCharList.length - iCharIdx - 1;
        }

        var strThisChar:String = aCharList[iCharIdx];

        if (strThisChar == null || strThisChar == ' ') {
          strThisChar = '&nbsp;';
        }

        if (bColor) {
          strChars += '<span style=\'color:rgb(' + iRed + ',' + iGreen + ',' + iBlue + ');' +
            (bBlock ? 'background-color:rgb(' + iRed + ',' + iGreen + ',' + iBlue + ');' : '') +
            (bAlpha ? 'opacity:' + (iAlpha / 255) + ';' : '') +
            '\'>' + strThisChar + '</span>';
        } else {
          strChars += strThisChar;
        }
      }

      strChars += '<br/>';
    }

    oAscii.innerHTML = '<tr><td style="display:block;width:' + width + 'px;height:' + height + 'px;overflow:hidden">' + strChars + '</td></tr>';
  }
}