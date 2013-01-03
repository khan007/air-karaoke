/*
 * CD+G reader
 * Reads and renders CD+G file used in Karaoke
 * 
 * @version: 0.9
 * @date: 02/01/2013
 * @author: Guo-Hao (Andrew) Lay
 * @Usage:
 *   1. Create an instance of this class.
 *   2. Call LoadCDG to load the file
 *   3. Call render function using a frame loop
 * @Reference: 
 *   - CDG File structure reference: http://jbum.com/cdg_revealed.html
 *   - CDG AS3 bytearray handling: http://www.as3.ro/blog/archives/261
 *   - CDG_toolkit (JAVA): http://code.google.com/p/cdg-toolkit/
*/

package org.dynamiclab{

	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.events.Event;
	import flash.utils.getTimer;
	import flash.geom.Point;
	import flash.geom.Matrix;
	import flash.display.Sprite;

	public class CDG extends Sprite {

		public static const EOF:String = "EndOfFile";
		private const SC_MASK = 0x3F;
		private const CDG_CMD = 0x09;
		private const MEMORY_PRESET = 1;
		private const BORDER_PRESET = 2;
		private const TILE_BLOCK_NORMAL = 6;
		private const TILE_BLOCK_XOR = 38;
		private const SCROLL_PRESET = 20;
		private const SCROLL_COPY = 24;
		private const DEFINE_TRANSPARENT_COLOR = 28;
		private const LOAD_COLOR_TABLE_LO = 30;
		private const LOAD_COLOR_TABLE_HIGH = 31;
		private const WIDTH = 320;
		private const HEIGHT = 216;

		private var _cdgByte:ByteArray;
		private var _currentPos:int = -1;
		private var _colorTable:Array = new Array();
		private var _bkgColor:Number;
		private var _transparentColorIndex:int;
		private var _currentPacket:uint;
		private var _lastRanderdPosition:Number;
		private var _cTransform:ColorTransform = new ColorTransform();
		private var _rect:Rectangle = new Rectangle(0,0,WIDTH,HEIGHT);
		private var _width:uint,_height:uint;
		private var _cdgBitmap:Bitmap;
		private var _pixelColorIndex:Array;

		public function CDG(w:uint, h:uint) {
			// constructor code
			_width = w;
			_height = h;

			_cdgBitmap = new Bitmap();
			_cdgBitmap.smoothing = true;

			this.addChild(_cdgBitmap);
		}

		public function loadCDG(filename:String):void {
			var fileLoader:URLLoader = new URLLoader();
			var fileRequest:URLRequest = new URLRequest(filename);

			fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
			fileLoader.addEventListener(Event.COMPLETE, _loadComplete);
			fileLoader.load(fileRequest);
		}

		function _loadComplete(e:Event):void {
			var loader:URLLoader = e.target as URLLoader;
			_cdgByte = loader.data;

			// initialize settings
			_currentPos = 0;
			_currentPacket = 0;
			_lastRanderdPosition = 0;
			_transparentColorIndex = -1;
			
			_pixelColorIndex = new Array();
			dispatchEvent(e);
		}

		public function render(tempPos:int, transparent:Boolean = false):void {
			// update pixel color data
			for (var i:int = _currentPos; i < tempPos; i++) {
				_draw(i);
			}
			_currentPos = tempPos;
			
			// populate the bitmap data from the indexed color table
			var bitData:BitmapData;
			if (_transparentColorIndex > -1 && transparent) {
				// create 32 bit transparent bitmap
				bitData = new BitmapData(WIDTH,HEIGHT,true,0x00000000);
				
				for (var y:uint = 0; y < HEIGHT; y++) {
					for (var x:uint = 0; x < WIDTH; x++) {
						var index:uint = _pixelColorIndex[y * WIDTH + x];
						var opacity:uint = (index == _transparentColorIndex) ? 0x00000000 : 0xff000000;
						bitData.setPixel32(x, y, _colorTable[index] + opacity);
					}
				}
			} else {
				// create solid bitmap with bkg removal
				bitData = new BitmapData(WIDTH,HEIGHT,false,0x000000);
				
				for (var y:uint = 0; y < HEIGHT; y++) {
					for (var x:uint = 0; x < WIDTH; x++) {
						bitData.setPixel(x, y, _colorTable[_pixelColorIndex[y * WIDTH + x]]);
					}
				}
			}

			// find min scale & upscale picture
			var scale:Number = Math.min(_width/WIDTH, _height/HEIGHT);
			var bd:BitmapData = new BitmapData(WIDTH*scale, HEIGHT*scale, true, 0x00000000);
			var m:Matrix = new Matrix();
			m.scale(scale, scale);
			bd.draw(bitData, m);

			if (_transparentColorIndex == -1 && transparent && !isNaN(_bkgColor)) {
				// removes the background color of the CDG file if transparent color is not defined
				bd.threshold(bd, new Rectangle(0,0,WIDTH*scale,HEIGHT*scale), new Point(0,0), "==", _bkgColor+0xff000000, 0x00000000, 0xFFFFFFFF, true);
			}

			_cdgBitmap.bitmapData = bd;
		}

		public function setSize(w:uint, h:uint):void {
			_width = w;
			_height = h;

			// center the bitmap
			var scale:Number = Math.min(_width/WIDTH, _height/HEIGHT);
			_cdgBitmap.x = (_width - WIDTH * scale) / 2;
			_cdgBitmap.y = (_height - HEIGHT * scale) / 2;
		}

		private function _draw(e:int) {
			var i = _currentPacket * 24;
			_currentPacket++;

			// is it end of file?
			if (i > _cdgByte.length) {
				var evt:Event = new Event(EOF);
				dispatchEvent(evt);
				return false;
			}

			// start reading CDG file
			var percent = i / _cdgByte.length;
			if (Number(_cdgByte[i] & SC_MASK) == Number(CDG_CMD)) {
				var type:Number = Number(_cdgByte[i + 1] & SC_MASK);
				switch (type) {
					case MEMORY_PRESET :
						_bkgColor = _colorTable[int(_cdgByte[i + 4] & 0x0F)];
						var repeat = _cdgByte[i + 5] & 0x0F;
						if (repeat == 0) {
							// clear screen
							_clearScreen(int(_cdgByte[i + 4] & 0x0F));
						}
						break;

					case BORDER_PRESET :
						// _cdgByte[i+4] & 0x0F;
						break;
					case TILE_BLOCK_NORMAL :
					case TILE_BLOCK_XOR :
						var color0 = Number(_cdgByte[i + 4] & 0x0F);
						var color1 = Number(_cdgByte[i + 5] & 0x0F);

						var row = int(_cdgByte[i + 6] & 0x1F) * 12;
						var column = int(_cdgByte[i + 7] & SC_MASK) * 6;
						
						for (var y:uint = 0; y < 12; y++) {
							var scanline:uint = _cdgByte[i + 8 + y] & SC_MASK;
							for (var l:uint =0; l< 6; l++) {
								var color:int = int(scanline & 0x1) == 0 ? color0:color1;

								// do XOR calculation if need to
								if (type == TILE_BLOCK_XOR) {
									color = _pixelColorIndex[(column+(5-l)) + (row+y)*WIDTH] ^ color;
								}
								_pixelColorIndex[(column+(5-l)) + (row+y)*WIDTH] = color;								
								scanline = scanline >> 1;
							}
						}
						break;
					case DEFINE_TRANSPARENT_COLOR :
						_transparentColorIndex = int(_cdgByte[i + 4] & 0x0F);
						break;
					case LOAD_COLOR_TABLE_LO :
					case LOAD_COLOR_TABLE_HIGH :
						var startIndex = type == LOAD_COLOR_TABLE_HIGH ? 8:0;
						for (var m:uint = 0; m<8; m++) {
							var cdgColor:Array = decodeColor(_cdgByte[i + 4 + m * 2],_cdgByte[i + 5 + m * 2]);
							_colorTable[m + startIndex] = _RGBToHex(cdgColor[0] * 17,cdgColor[1] * 17,cdgColor[2] * 17);
						}
						break;
				}
			}
		}

		private function _RGBToHex(r, g, b ) {
			var hex = r << 16 ^ g << 8 ^ b;

			return hex;
		}

		private function _clearScreen(color) {
			for (var y:uint = 0; y < HEIGHT; y++) {
				for (var x:uint = 0; x < WIDTH; x++) {
					// fill every pixel with one color
					_pixelColorIndex[y * WIDTH + x] = color;
				}
			}
		}

		public function decodeColor(high, low):Array {
			return new Array (
			 ((high & SC_MASK) >> 2),
			 (((high & 0x3) << 2) | ((low >> 4) & 0x3)),
			 (low & 0x0F)
			);
		}
	}
}