package
{
	import flash.desktop.NativeApplication;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.filesystem.File;
	import flash.system.LoaderContext;
	import project.SWFData;
	
	public class Main extends Sprite 
	{
		private var file:File;
		
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
			var swf:SWFData = new SWFData(file.data);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.stageWidth = swf.frameSize.width;
			stage.stageHeight = swf.frameSize.height;
			
			stage.frameRate = swf.frameRate;
			stage.color = swf.backgroundColor;
			
			var loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext();
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				addChild(loader);
			});
			
			loaderContext.allowCodeImport = true;
			loader.loadBytes(file.data, loaderContext);
		}
	}
}