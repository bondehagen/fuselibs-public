

using Fuse;
using Fuse.Elements;

using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Platform;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content.Fonts;
using Uno.Content.Images;
using Fuse.Drawing;

namespace Fuse.Controls.FallbackTextRenderer
{
	[TargetSpecificImplementation]
	static class CanvasTextRendererImpl
	{
		[TargetSpecificImplementation]
		public static CanvasTextRendererHandle Create(string fontName)
		{
			return null;
		}

		[TargetSpecificImplementation]
		public static float MeasureStringVirtual(CanvasTextRendererHandle handle, string s)
		{
			return 0.0f;
		}

		[TargetSpecificImplementation]
		public static void BeginRendering(CanvasTextRendererHandle handle, int width, int height, float fontSize)
		{
		}

		[TargetSpecificImplementation]
		public static void DrawText(CanvasTextRendererHandle handle, float x, float y, string s)
		{
		}

		[TargetSpecificImplementation]
		public static Bitmap EndRendering(CanvasTextRendererHandle handle, int width, int height)
		{
			return new Bitmap(int2(0), Format.L8, new Buffer(new byte[0]));
		}

		[TargetSpecificImplementation]
		public static void UpdateFontName(CanvasTextRendererHandle handle, string fontName)
		{
		}

		[TargetSpecificImplementation]
		public static void UpdateFontSize(CanvasTextRendererHandle handle, float fontSize)
		{
		}
	}

	[TargetSpecificType]
	class CanvasTextRendererHandle
	{
	}

	// TODO: Should maybe be internal?
	sealed class DefaultTextRenderer
	{
		FontFace _fontFace;
		public FontFace FontFace
		{
			get { return _fontFace; }
			set
			{
				if (value == _fontFace)
					return;

				_fontFace = value;
				CanvasTextRendererImpl.UpdateFontName(_handle, _fontFace.StyleName);
			}
		}

		readonly CanvasTextRendererHandle _handle;

		texture2D _tex; // TODO: Leaks..?

		public DefaultTextRenderer(FontFace fontFace)
		{
			_fontFace = fontFace;
			_handle = CanvasTextRendererImpl.Create(_fontFace.StyleName);
		}

		public float GetLineHeight(float fontSize)
		{
			return fontSize * 1.5f;
		}

		public float GetLineHeightVirtual(float fontSize, float absoluteZoom)
		{
			return GetLineHeight(fontSize) / absoluteZoom;
		}

		public float2 MeasureString(float fontSize, float absoluteZoom, string s)
		{
			if (s == null)
				return float2(0);

			float fs = fontSize * absoluteZoom;

			CanvasTextRendererImpl.UpdateFontSize(_handle, fs);
			return float2(CanvasTextRendererImpl.MeasureStringVirtual(_handle, s), GetLineHeight(fs));
		}

		public float2 MeasureStringVirtual(float fontSize, float absoluteZoom, string s)
		{
			return MeasureString(fontSize, absoluteZoom, s) / absoluteZoom;
		}

		float _fontSize;
		float _absoluteZoom;
		float2 _origin, _bounds;

		float4x4 _transform;
		float4 _textColor;
		int _w, _h;

		public void BeginRendering(float fontSize, float absoluteZoom, float4x4 worldTransform, 
			float2 bounds, float4 textColor, int maxTextLength)
		{
			_fontSize = fontSize;
			_absoluteZoom = absoluteZoom;

			_transform = worldTransform;
			_bounds = bounds * _absoluteZoom;

			_textColor = textColor;

			_w = Math.Max((int)Math.Ceil(_bounds.X), 1);
			_h = Math.Max((int)Math.Ceil(_bounds.Y), 1);

			CanvasTextRendererImpl.BeginRendering(_handle, _w, _h, _fontSize * _absoluteZoom);
		}

		public void EndRendering(DrawContext dc)
		{
			var bitmap = CanvasTextRendererImpl.EndRendering(_handle, _w, _h);

			if (_tex != null && (_tex.Size.X != bitmap.Size.X || _tex.Size.Y != bitmap.Size.Y))
				_tex.Dispose();

			_tex = new texture2D(bitmap.Size, bitmap.Format, false);
			_tex.Update(bitmap.Buffer);

			draw
			{
				float2[] Vertices: new []
				{
					float2(0, 0), float2(0, 1), float2(1, 1),
					float2(0, 0), float2(1, 1), float2(1, 0)
				};

				float2 Coord: vertex_attrib(Vertices);

				float4 LocalPosition: float4(Coord * float2(_w,_h),0,1);
				float4 WorldPosition: Vector.Transform(LocalPosition, _transform);
				ClipPosition: Vector.Transform(WorldPosition, dc.Viewport.ViewProjectionTransform);

				apply Fuse.Drawing.PreMultipliedAlphaCompositing;

				CullFace: dc.CullFace;
				DepthTestEnabled: false;

				float TextureColor: Math.Pow(sample(_tex, Coord).Z, 2.2f);

				PixelColor: float4(_textColor.XYZ, TextureColor * _textColor.W);
			};
		}

		public void DrawLine(DrawContext dc, float x, float y, string line)
		{
            float adjustedX = Math.Floor(x * dc.ViewportPixelsPerPoint + 0.5f);
            float adjustedY = Math.Floor((y + GetLineHeight(_fontSize) / 2.0f) * _absoluteZoom);

			CanvasTextRendererImpl.DrawText(_handle, adjustedX, adjustedY, line);
		}
	}
}
