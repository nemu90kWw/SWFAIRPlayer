package
{
	import flash.desktop.NativeApplication;
	import flash.display.Loader;
	import flash.display.NativeWindowDisplayState;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.InvokeEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.events.NativeWindowDisplayStateEvent;
	import flash.filesystem.File;
	import flash.system.LoaderContext;
	import project.Menu;
	import project.SWFData;
	
	public class Main extends Sprite 
	{
		private var file:File;
		private var swf:SWFData;
		
		private var menu:Menu;
		private var currentWindowScale:Number;
		
		public function Main() 
		{
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
		}
		
		private function onInvoke(e:InvokeEvent):void
		{
			if(e.arguments.length != 0)
			{
				file = new File(e.arguments[0]);
				file.addEventListener(Event.COMPLETE, onComplete);
				file.load();
			}
		}
		
		private function onComplete(e:Event):void
		{
			swf = new SWFData(file.data);
			menu = new Menu(stage.nativeWindow, swf.frameSize, this);
			
			stage.frameRate = swf.frameRate;
			stage.color = swf.backgroundColor;
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZING, onResizing);
			stage.nativeWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGING, onDisplayStateChanging);
			setWindowScale(1);
			
			var loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext();
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				addChild(loader);
			});
			
			loaderContext.allowCodeImport = true;
			loader.loadBytes(file.data, loaderContext);
		}
		
		private function onDisplayStateChanging(e:NativeWindowDisplayStateEvent):void 
		{
			// 最大化の代わりにフルスクリーンにする
			if (e.afterDisplayState == NativeWindowDisplayState.MAXIMIZED)
			{
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
				e.preventDefault();
			}
		}
		
		private function get contentWidth():int
		{
			return Math.round(swf.frameSize.width / stage.contentsScaleFactor);
		}
		
		private function get contentHeight():int
		{
			return Math.round(swf.frameSize.height / stage.contentsScaleFactor);
		}
		
		private function onResizing(e:NativeWindowBoundsEvent):void
		{
			// アスペクト比固定での整数倍ウィンドウ拡縮
			var afterScaleX:Number = (e.afterBounds.width + e.beforeBounds.x - e.afterBounds.x - stage.nativeWindow.width + stage.stageWidth) / contentWidth;
			var afterScaleY:Number = (e.afterBounds.height + e.beforeBounds.y - e.afterBounds.y - stage.nativeWindow.height + stage.stageHeight) / contentHeight;
			var maxScale:Number = Math.min(Screen.mainScreen.visibleBounds.width / contentWidth, Screen.mainScreen.visibleBounds.height / contentHeight);
			
			setWindowScale(Math.min(Math.max((afterScaleX + afterScaleY) / 2, 1), maxScale));
			
			stage.nativeWindow.x = e.afterBounds.x;
			stage.nativeWindow.y = e.afterBounds.y;
			
			e.preventDefault();
		}
		
		private function setWindowScale(value:Number):void
		{
			stage.stageWidth = contentWidth * value;
			stage.stageHeight = contentHeight * value;
			
			fitScreen();
		}
		
		private function fitScreen():void
		{
			var scaleX:Number = stage.stageWidth / contentWidth;
			var scaleY:Number = stage.stageHeight / contentHeight;
			
			scaleX = scaleY = Math.min(scaleX, scaleY);
			
			root.scaleX = scaleX / stage.contentsScaleFactor;
			root.scaleY = scaleY / stage.contentsScaleFactor;
			root.x = (stage.stageWidth - contentWidth * scaleX) / 2;
			root.y = (stage.stageHeight - contentHeight * scaleY) / 2;
		}
		
		private function onFullScreen(e:FullScreenEvent):void 
		{
			if(e.fullScreen == true) {
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			}
			else {
				stage.displayState = StageDisplayState.NORMAL;
			}
			
			fitScreen();
		}
	}
}