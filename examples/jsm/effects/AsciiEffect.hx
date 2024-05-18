package three.js.examples.javascript.effects;

import js.html.Document;
import js.html.Element;
import js.html TableName;
import js.html.TableRow;
import js.html.TableData;
import js.html.SpanElement;
import js.Browser.console;

class AsciiEffect {
    private var renderer:Dynamic;
    private var charSet:String;
    private var options:Dynamic;
    private var fResolution:Float;
    private var iScale:Int;
    private var bColor:Bool;
    private var bAlpha:Bool;
    private var bBlock:Bool;
    private var bInvert:Bool;
    private var strResolution:String;
    private var width:Int;
    private var height:Int;
    private var domElement:Element;
    private var oAscii:TableName;
    private var iWidth:Int;
    private var iHeight:Int;
    private var oImg:Element;
    private var aDefaultCharList:Array<String>;
    private var aDefaultColorCharList:Array<String>;
    private var strFont:String;
    private var fFontSize:Float;
    private var fLineHeight:Float;
    private var fLetterSpacing:Float;
    private var oCanvas:js.html.CanvasElement;
    private var oCtx:js.html.CanvasRenderingContext2D;
    private var oCanvasImg:Element;

    public function new(renderer:Dynamic, charSet:String = ' .:-=+*#%@', options:Dynamic = {}) {
        this.renderer = renderer;
        this.charSet = charSet;
        this.options = options;

        fResolution = options['resolution'] || 0.15;
        iScale = options['scale'] || 1;
        bColor = options['color'] || false;
        bAlpha = options['alpha'] || false;
        bBlock = options['block'] || false;
        bInvert = options['invert'] || false;
        strResolution = options['strResolution'] || 'low';

        width = 0;
        height = 0;

        domElement = Document.createElement('div');
        domElement.style.cursor = 'default';

        oAscii = Document.createElement('table');
        domElement.appendChild(oAscii);

        iWidth = 0;
        iHeight = 0;
        oImg = null;

        setSize = function(w:Int, h:Int) {
            width = w;
            height = h;

            renderer.setSize(w, h);

            initAsciiSize();
        };

        render = function(scene:Dynamic, camera:Dynamic) {
            renderer.render(scene, camera);
            asciifyImage(oAscii);
        };

        domElement = domElement;

        initAsciiSize();

        aDefaultCharList = (' .,:;i1tfLCG08@').split('');
        aDefaultColorCharList = (' CGO08@').split('');
        strFont = 'courier new, monospace';

        oCanvasImg = renderer.domElement;

        oCanvas = Document.createElement('canvas');
        if (!oCanvas.getContext) {
            return;
        }

        oCtx = oCanvas.getContext('2d');
        if (!oCtx.getImageData) {
            return;
        }

        var aCharList:Array<String> = (bColor ? aDefaultColorCharList : aDefaultCharList);

        if (charSet) aCharList = charSet.split('');

        fFontSize = (2 / fResolution) * iScale;
        fLineHeight = (2 / fResolution) * iScale;

        switch (strResolution) {
            case 'low':
                switch (iScale) {
                    case 1: fLetterSpacing = 0;
                    case 2: fLetterSpacing = -2.1;
                    case 3: fLetterSpacing = -3.1;
                    case 4: fLetterSpacing = -4.1;
                    case 5: fLetterSpacing = -5.1;
                }
            case 'medium':
                switch (iScale) {
                    case 1: fLetterSpacing = 0;
                    case 2: fLetterSpacing = -1;
                    case 3: fLetterSpacing = -1.04;
                    case 4: fLetterSpacing = -2.1;
                    case 5: fLetterSpacing = -2.5;
                }
            case 'high':
                switch (iScale) {
                    case 1: fLetterSpacing = 0;
                    case 2: fLetterSpacing = -1;
                    case 3: fLetterSpacing = -1.04;
                    case 4: fLetterSpacing = -2.1;
                    case 5: fLetterSpacing = -2.5;
                }
        }
    }

    private function initAsciiSize() {
        iWidth = Math.floor(width * fResolution);
        iHeight = Math.floor(height * fResolution);

        oCanvas.width = iWidth;
        oCanvas.height = iHeight;

        oImg = renderer.domElement;

        if (oImg.style.backgroundColor) {
            oAscii.rows[0].cells[0].style.backgroundColor = oImg.style.backgroundColor;
            oAscii.rows[0].cells[0].style.color = oImg.style.color;
        }

        oAscii.cellSpacing = 0;
        oAscii.cellPadding = 0;

        var oStyle:Dynamic = oAscii.style;
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

    private function asciifyImage(oAscii:TableName) {
        oCtx.clearRect(0, 0, iWidth, iHeight);
        oCtx.drawImage(oCanvasImg, 0, 0, iWidth, iHeight);
        var oImgData:Array<Float> = oCtx.getImageData(0, 0, iWidth, iHeight).data;

        var strChars:String = '';

        for (y in 0...iHeight) {
            for (x in 0...iWidth) {
                var iOffset:Int = (y * iWidth + x) * 4;

                var iRed:Int = oImgData[iOffset];
                var iGreen:Int = oImgData[iOffset + 1];
                var iBlue:Int = oImgData[iOffset + 2];
                var iAlpha:Int = oImgData[iOffset + 3];
                var iCharIdx:Int;

                var fBrightness:Float;

                fBrightness = (0.3 * iRed + 0.59 * iGreen + 0.11 * iBlue) / 255;

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
                    strChars += '<span style=\'color:rgb(' + iRed + ',' + iGreen + ',' + iBlue + ');';
                    if (bBlock) {
                        strChars += 'background-color:rgb(' + iRed + ',' + iGreen + ',' + iBlue + ');';
                    }
                    if (bAlpha) {
                        strChars += 'opacity:' + (iAlpha / 255) + ';';
                    }
                    strChars += '\'>' + strThisChar + '</span>';
                } else {
                    strChars += strThisChar;
                }
            }

            strChars += '<br/>';
        }

        oAscii.innerHTML = '<tr><td style=\'display:block;width:${width}px;height:${height}px;overflow:hidden\'>${strChars}</td></tr>';
    }
}