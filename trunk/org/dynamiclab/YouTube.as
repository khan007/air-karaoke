package org.dynamiclab{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.system.Security;
	import flash.net.URLLoader;
	import flash.events.UncaughtErrorEvent;
	import flash.events.IOErrorEvent;

	public class YouTube extends Sprite {

		// This will hold the API player instance once it is initialized.;
		private var _player:Object;
		private var _loader:Loader;
		private var _youtubeIndex:uint = 0;
		private var _searchResult:Object;
		private var _width:uint, _height:uint;
		
		public static const READY:String = "Ready";
		public static const NO_VIDEO:String = "NoVideo";

		public function YouTube(w:uint, h:uint) {
			// constructor code
			_width = w;
			_height = h;

			// The player SWF file on www.youtube.com needs to communicate with your host
			// SWF file. Your code must call Security.allowDomain() to allow this
			// communication.
			//Security.allowDomain("www.youtube.com");
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.INIT, _onLoaderInit);
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, _onIOError);
			_loader.load(new URLRequest("http://www.youtube.com/apiplayer?version=3&iv_load_policy=3&modestbranding=1&rel=0&showinfo=0"));
			
			// catch global unhandled error
			_loader.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, _uncaughtErrorHandler);
		}
		
		public function findAndPlay(query:String):void {
			if (_player) {
				var queryRequest:URLRequest = new URLRequest("http://gdata.youtube.com/feeds/api/videos?q="+escape(query)+"&alt=json&format=5&safeSearch=strict&v=2&max-results=10");
				var queryLoader:URLLoader = new URLLoader(queryRequest);
				queryLoader.addEventListener(Event.COMPLETE, _onSearchComplete);
			} else {
				dispatchEvent(new Event(NO_VIDEO));
			}
		}
		
		public function setSize(w:uint, h:uint):void {
			_width = w;
			_height = h;
			
			if (_player) {
				// Set appropriate player dimensions for your application
				_player.setSize(_width, _height);
			}
		}
		
		public function stop():void {
			if (_player) {
				_player.stopVideo();
			}
		}
		
		private function _onSearchComplete(e:Event):void {
			_searchResult = JSON.parse(e.target.data);
			_youtubeIndex = 0;
			
			// 1. extract the id
			// 2. call to play video
			// check if there's app control
			var valid:Boolean = true;
			
			while (!valid && _searchResult.feed.entry.length -1 > _youtubeIndex) {
				if (_searchResult.feed.entry[_youtubeIndex].app$control != null) {
					if (!_searchResult.feed.entry[_youtubeIndex].app$control.yt$state.name == "restricted") {
						valid = true;
					}
				}
				
				if (!valid) {
					_youtubeIndex++;
				}
			}
			
			if (valid) {
				_player.stopVideo();
				_player.loadVideoById(_searchResult.feed.entry[_youtubeIndex].media$group.yt$videoid.$t);
				_player.mute();
			} else {
				dispatchEvent(new Event(NO_VIDEO));
			}
		}
		
		private function _onLoaderInit(event:Event):void {
			addChild(_loader);
			_loader.content.addEventListener("onReady", _onPlayerReady);
			_loader.content.addEventListener("onError", _onPlayerError);
			_loader.content.addEventListener("onStateChange", _onPlayerStateChange);
			_loader.content.addEventListener("onPlaybackQualityChange", _onVideoPlaybackQualityChange);
		}

		private function _onPlayerReady(event:Event):void {
			// Event.data contains the event parameter, which is the Player API ID 
			trace("player ready:", Object(event).data);

			// Once this event has been dispatched by the player, we can use
			// cueVideoById, loadVideoById, cueVideoByUrl and loadVideoByUrl
			
			// to load a particular YouTube video.
			_player = _loader.content;
			this.setSize(_width, _height);
			
			dispatchEvent(new Event(READY));
		}

		private function _onPlayerError(event:Event):void {
			// Event.data contains the event parameter, which is the error code
			trace("player error:", Object(event).data);
			switch (Object(event).data) {
				case 101:
				case 150:
					if (_searchResult.feed.entry.length -1 > _youtubeIndex) {
						_youtubeIndex++;
						_player.loadVideoById(_searchResult.feed.entry[_youtubeIndex].media$group.yt$videoid.$t);
						_player.mute();
					} else {
						dispatchEvent(new Event(NO_VIDEO));
					}
					break;
			}
		}

		private function _onPlayerStateChange(event:Event):void {
			// Event.data contains the event parameter, which is the new player state
			trace("player state:", Object(event).data);
		}

		private function _onVideoPlaybackQualityChange(event:Event):void {
			// Event.data contains the event parameter, which is the new video quality
			trace("video quality:", Object(event).data);
		}
		
		private function _onIOError(evt:Event):void {
			trace("YouTube video disabled.");
			dispatchEvent(new Event(READY));
		}

		private function _uncaughtErrorHandler(e:UncaughtErrorEvent):void {
			trace(e.error);
			e.preventDefault();
		}
	}

}