package com {
	import flash.text.TextField;
	import flash.utils.setTimeout;
	
	public class Notify {

		private static var _tf:TextField;
		private static var _delay:Number;
		
		private static const DELAY_SHORT:Number = 2000;
		
		public function Notify() {
			// constructor code
		}
		
		public static function init(tf:TextField):void {
			_tf = tf;
		}
		
		public static function show(str:String):void {
			_tf.text = str;
			_tf.visible = true;
			_delay = setTimeout(_hide, DELAY_SHORT);
		}
		
		private static function _hide():void {
			_tf.visible = false;
		}

	}
	
}
