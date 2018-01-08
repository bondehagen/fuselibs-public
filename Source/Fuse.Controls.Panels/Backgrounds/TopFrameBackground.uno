using Uno;

using Fuse.Elements;
using Fuse.Platform;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls
{
	/** Compensates for space taken up by the status bar.

		`StatusBarBackground` will always have the same size as the status bar across all platforms and devices.

		## Example

		The following example demonstrates how a `StatusBarBackground` can be docked inside a `DockPanel` to ensure the rest of the app's content (inside by the `Panel`) will be placed below the status bar.

			<DockPanel>
				<StatusBarBackground Dock="Top"/>
				<Panel>
					<Text>This text will be below the status bar</Text>
				</Panel>
			</DockPanel>

		See also @BottomBarBackground.
	*/
	public class StatusBarBackground : TopFrameBackground { }

	public class TopFrameBackground: Control
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			if defined(iOS || Android)
				SystemUI.TopFrameWillResize += OnFrameResized;
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			if defined(iOS || Android)
				SystemUI.TopFrameWillResize -= OnFrameResized;
		}

		extern(ANDROID || IOS)
		private void OnFrameResized(object sender, SystemUIWillResizeEventArgs args)
		{
			InvalidateLayout();
		}

		protected override float2 GetContentSize(LayoutParams lp)
		{
			if defined(iOS || Android)
			{
				var pixelsPerPoint = 1.0f;
				if (AppBase.Current != null)
					pixelsPerPoint = AppBase.Current.PixelsPerPoint;
				return SystemUI.TopFrame.Size / pixelsPerPoint;
			}
			return float2(0,0);
		}
	}

}
