package three.js.examples.jsm.effects;

import js.Browser;
import js.html.HTMLDivElement;
import js.html.HTMLTableElement;
import js.html.HTMLCanvasElement;
import js.html.HTMLImageElement;
import js.html.CanvasRenderingContext2D;

class AsciiEffect {

    var renderer:Renderer;
    var charSet:String;
    var options:Options;
    var width:Float;
    var height:Float;
    var domElement:HTMLDivElement;
    var oAscii:HTMLTableElement;
    var iWidth:Int;
    var iHeight:Int;
    var oImg:HTMLImageElement;
    var oCanvas:HTMLCanvasElement;
    var oCtx:CanvasRenderingContext2D;
    var aCharList:Array<String>;
    var strFont:String;
    var fFontSize:Float;
    var fLineHeight:Float;
    var fLetterSpacing:Float;

    typedef Options = {
        resolution:Float,
        scale:Int,
        color:Bool,
        alpha:Bool,
        block:Bool,
        invert:Bool,
        strResolution:String
    }

    public function new(renderer:Renderer, charSet:String = ' .:-=+*#%@', options:Options = {}) {
        this.renderer = renderer;
        this.charSet = charSet;
        this.options = options;

        var fResolution = options.resolution ?? 0.15;
        var iScale = options.scale ?? 1;
        var bColor = options.color ?? false;
        var bAlpha = options.alpha ?? false;
        var bBlock = options.block ?? false;
        var bInvert = options.invert ?? false;
        var strResolution = options.strResolution ?? 'low';

        domElement = Browser.document.createElement('div');
        domElement.style.cursor = 'default';

        oAscii = Browser.document.createElement('table');
        domElement.appendChild(oAscii);

        oCanvas = Browser.document.createElement('canvas');
        if (!oCanvas.getContext) {
            return;
        }

        oCtx = oCanvas.getContext('2d');
        if (!oCtx.getImageData) {
            return;
        }

        aCharList = (bColor ? [' ', 'C', 'G', 'O', '0', '8', '@'] : [' ', '.', ',', ':', ';', 'i', '1', 't', 'f', 'L', 'C', 'G', '0', '8', '@']).split('');

        strFont = 'courier new, monospace';

        fFontSize = (2 / fResolution) * iScale;
        fLineHeight = (2 / fResolution) * iScale;

        fLetterSpacing = 0;

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

    public function setSize(w:Float, h:Float) {
        width = w;
        height = h;

        renderer.setSize(w, h);

        initAsciiSize();
    }

    public function render(scene:Scene, camera:Camera) {
        renderer.render(scene, camera);
        asciifyImage(oAscii);
    }

    private function initAsciiSize() {
        iWidth = Math.floor(width * options.resolution ?? 0.15);
        iHeight = Math.floor(height * options.resolution ?? 0.15);

        oCanvas.width = iWidth;
        oCanvas.height = iHeight;

        oImg = renderer.domElement;

        if (oImg.style.backgroundColor) {
            oAscii.rows[0].cells[0].style.backgroundColor = oImg.style.backgroundColor;
            oAscii.rows[0].cells[0].style.color = oImg.style.color;
        }
    }

    private function asciifyImage(oAscii:HTMLTableElement) {
        oCtx.clearRect(0, 0, iWidth, iHeight);
        oCtx.drawImage(oImg, 0, 0, iWidth, iHeight);
        var oImgData = oCtx.getImageData(0, 0, iWidth, iHeight).data;

        var strChars = '';

        for (y in 0...iHeight by 2) {
            for (x in 0...iWidth) {
                var iOffset = (y * iWidth + x) * 4;

                var iRed = oImgData[iOffset];
                var iGreen = oImgData[iOffset + 1];
                var iBlue = oImgData[iOffset + 2];
                var iAlpha = oImgData[iOffset + 3];
                var iCharIdx;

                var fBrightness;

                fBrightness = (0.3 * iRed + 0.59 * iGreen + 0.11 * iBlue) / 255;

                if (iAlpha == 0) {
                    fBrightness = 1;
                }

                iCharIdx = Math.floor((1 - fBrightness) * (aCharList.length - 1));

                if (options.invert ?? false) {
                    iCharIdx = aCharList.length - iCharIdx - 1;
                }

                var strThisChar = aCharList[iCharIdx];

                if (strThisChar == null || strThisChar == ' ') {
                    strThisChar = '&nbsp;';
                }

                if (options.color ?? false) {
                    strChars += '<span style=\''
                        + 'color:rgb(' + iRed + ',' + iGreen + ',' + iBlue + ');'
                        + (options.block ?? false ? 'background-color:rgb(' + iRed + ',' + iGreen + ',' + iBlue + ');' : '')
                        + (options.alpha ?? false ? 'opacity:' + (iAlpha / 255) + ';' : '')
                        + '\'>' + strThisChar + '</span>';
                } else {
                    strChars += strThisChar;
                }
            }

            strChars += '<br/>';
        }

        oAscii.innerHTML = '<tr><td style="display:block;width:' + width + 'px;height:' + height + 'px;overflow:hidden">' + strChars + '</td></tr>';
    }
}