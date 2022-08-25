package
{
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragManager;
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
	import flash.events.NativeDragEvent;
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
		
		private var container:Sprite;
		private var focusRect:Sprite;
		
		public function Main() 
		{
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
		}
		
		private function onInvoke(e:InvokeEvent):void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			focusRect = new Sprite();
			focusRect.graphics.beginFill(0xFFFFFF);
			focusRect.graphics.drawRect(0, 0, 1000, 1000);
			
			focusRect.scaleX = stage.stageWidth;
			focusRect.scaleY = stage.stageHeight;
			
			addChild(focusRect);
			
			container = new Sprite();
			addChild(container);
			
			if(e.arguments.length != 0)
			{
				file = new File(e.arguments[0]);
				file.addEventListener(Event.COMPLETE, onComplete);
				file.load();
				return;
			}
			
			var onDragEnter:Function = function(e:NativeDragEvent):void { NativeDragManager.acceptDragDrop(focusRect); };
			
			focusRect.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnter);
			focusRect.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, function(e:NativeDragEvent):void
			{
				if(e.clipboard.formats[0] == ClipboardFormats.FILE_LIST_FORMAT)
				{
					focusRect.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnter);
					focusRect.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, arguments.callee);
					
					file = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];
					file.addEventListener(Event.COMPLETE, onComplete);
					file.load();
				}
			});
		}
		
		private function onComplete(e:Event):void
		{
			swf = new SWFData(file.data);
			menu = new Menu(stage.nativeWindow, swf.frameSize, this);
			
			stage.frameRate = swf.frameRate;
			stage.color = swf.backgroundColor;
			
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZING, onResizing);
			stage.nativeWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGING, onDisplayStateChanging);
			setWindowScale(1);
			
			var loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext();
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				container.addChild(loader);
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
			stage.nativeWindow.bounds = e.afterBounds;
			fitScreen();
			
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
			
			container.scaleX = scaleX / stage.contentsScaleFactor;
			container.scaleY = scaleY / stage.contentsScaleFactor;
			container.x = (stage.stageWidth - contentWidth * scaleX) / 2;
			container.y = (stage.stageHeight - contentHeight * scaleY) / 2;
			
			focusRect.x = 0;
			focusRect.y = 0;
			focusRect.scaleX = stage.stageWidth / 1000;
			focusRect.scaleY = stage.stageHeight / 1000;
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