/**
 * Ascii generation is based on https://github.com/hassadee/jsascii/blob/master/jsascii.js
 *
 * 16 April 2012 - @blurspline
 */

class AsciiEffect {
    public var domElement:HTMLDivElement;
    public var oAscii:HTMLTable;
    private var oImg:HTMLImage;
    private var oCanvas:HTMLCanvasElement;
    private var oCtx:CanvasRenderingContext2D;
    private var aCharList:Array<String>;
    private var fFontSize:Float;
    private var fLineHeight:Float;
    private var fLetterSpacing:Float;
    private var strFont:String;
    private var width:Int;
    private var height:Int;
    private var iWidth:Int;
    private var iHeight:Int;
    private var renderer:Dynamic;
    private var fResolution:Float;
    private var iScale:Int;
    private var bColor:Bool;
    private var bAlpha:Bool;
    private var bBlock:Bool;
    private var bInvert:Bool;
    private var strResolution:String;

    public function new(renderer:Dynamic, charSet:String = " .:-=+*#%@", options:Dynamic = {}) {
        // ' .,:;=|iI+hHOE#`$';
        // darker bolder character set from https://github.com/saw/Canvas-ASCII-Art/
        // ' .\'`^",:;Il!i~+_-?][}{1)(|/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$'.split('');

        // Some ASCII settings
        fResolution = options["resolution"] / default 0.15; // Higher for more details
        iScale = options["scale"] / default 1;
        bColor = options["color"] / default false; // nice but slows down rendering!
        bAlpha = options["alpha"] / default false; // Transparency
        bBlock = options["block"] / default false; // blocked characters. like good O dos
        bInvert = options["invert"] / default false; // black is white, white is black
        strResolution = options["strResolution"] / default "low";

        domElement = window.document.createElement("div");
        domElement.style.cursor = "default";

        oAscii = window.document.createElement("table");
        domElement.appendChild(oAscii);

        iWidth = 0;
        iHeight = 0;

        this.renderer = renderer;

        aDefaultCharList = [" .,:;i1tfLCG08@"].split("");
        aDefaultColorCharList = [" CGO08@"].split("");
        strFont = "courier new, monospace";

        oCanvasImg = renderer.domElement;

        oCanvas = window.document.createElement("canvas");
        if (oCanvas.getContext == null) {
            return;
        }

        oCtx = oCanvas.getContext2d();
        if (oCtx.getImageData == null) {
            return;
        }

        aCharList = if (bColor) aDefaultColorCharList else aDefaultCharList;

        if (charSet != null) {
            aCharList = charSet.split("");
        }

        // Setup dom

        fFontSize = (2.0 / fResolution) * iScale;
        fLineHeight = (2.0 / fResolution) * iScale;

        // adjust letter-spacing for all combinations of scale and resolution to get it to fit the image width.

        fLetterSpacing = 0.0;

        switch (strResolution) {
            case "low":
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
                break;

            case "medium":
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
                break;

            case "high":
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
                break;
        }
    }

    public function setSize(w:Int, h:Int) {
        width = w;
        height = h;

        renderer.setSize(w, h);

        initAsciiSize();
    }

    public function render(scene:Dynamic, camera:Dynamic) {
        renderer.render(scene, camera);
        asciifyImage(oAscii);
    }

    private function initAsciiSize() {
        iWidth = Std.int(width * fResolution);
        iHeight = Std.int(height * fResolution);

        oCanvas.width = iWidth;
        oCanvas.height = iHeight;

        oImg = renderer.domElement;

        if (oImg.style.backgroundColor != null) {
            oAscii.rows[0].cells[0].style.backgroundColor = oImg.style.backgroundColor;
            oAscii.rows[0].cells[0].style.color = oImg.style.color;
        }

        oAscii.cellSpacing = 0;
        oAscii.cellPadding = 0;

        var oStyle = oAscii.style;
        oStyle.whiteSpace = "pre";
        oStyle.margin = "0px";
        oStyle.padding = "0px";
        oStyle.letterSpacing = fLetterSpacing + "px";
        oStyle.fontFamily = strFont;
        oStyle.fontSize = fFontSize + "px";
        oStyle.lineHeight = fLineHeight + "px";
        oStyle.textAlign = "left";
        oStyle.textDecoration = "none";
    }

    private function asciifyImage(oAscii:HTMLTable) {
        oCtx.clearRect(0, 0, iWidth, iHeight);
        oCtx.drawImage(oCanvasImg, 0, 0, iWidth, iHeight);
        var oImgData = oCtx.getImageData(0, 0, iWidth, iHeight).data;

        // Coloring loop starts now
        var strChars = "";

        for (y in 0...iHeight) {
            if (y % 2 == 0) {
                for (x in 0...iWidth) {
                    var iOffset = (y * iWidth + x) * 4;

                    var iRed = oImgData[iOffset];
                    var iGreen = oImgData[iOffset + 1];
                    var iBlue = oImgData[iOffset + 2];
                    var iAlpha = oImgData[iOffset + 3];
                    var iCharIdx:Int;

                    var fBrightness:Float;

                    fBrightness = (0.3 * iRed + 0.59 * iGreen + 0.11 * iBlue) / 255;

                    if (iAlpha == 0) {
                        fBrightness = 1; // should calculate alpha instead, but quick hack :)
                    }

                    iCharIdx = Std.int((1 - fBrightness) * (aCharList.length - 1));

                    if (bInvert) {
                        iCharIdx = aCharList.length - iCharIdx - 1;
                    }

                    var strThisChar = aCharList[iCharIdx];

                    if (strThisChar == null || strThisChar == " ") {
                        strThisChar = "&nbsp;";
                    }

                    if (bColor) {
                        strChars += "<span style='color:rgb(" + iRed + "," + iGreen + "," + iBlue + ";" +
                            (if (bBlock) "background-color:rgb(" + iRed + "," + iGreen + "," + iBlue + ";" else "") +
                            (if (bAlpha) "opacity:" + (iAlpha / 255) + ";" else "") +
                            "'>" + strThisChar + "</span>";
                    } else {
                        strChars += strThisChar;
                    }
                }
            }

            strChars += "<br/>";
        }

        oAscii.innerHTML = "<tr><td style='display:block;width:" + width + "px;height:" + height + "px;overflow:hidden'>" + strChars + "</td></tr>";
    }
}