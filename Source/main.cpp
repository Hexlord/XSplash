#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/Xfixes.h>
#include <X11/extensions/shape.h>
#include <assert.h>
#include <stdio.h>

#include <cairo/cairo-xlib.h>
#include <cairo/cairo.h>

#include <gif_lib.h>

#include <chrono>
#include <iostream>
#include <thread>

int main() {
  Display *d = XOpenDisplay(NULL);
  Window root = DefaultRootWindow(d);
  int default_screen = XDefaultScreen(d);

  // these two lines are really all you need
  XSetWindowAttributes attrs;
  attrs.override_redirect = true;

  XVisualInfo vinfo;
  if (!XMatchVisualInfo(d, DefaultScreen(d), 32, TrueColor, &vinfo)) {
    printf("No visual found supporting 32 bit color, terminating\n");
    exit(EXIT_FAILURE);
  }
  // these next three lines add 32 bit depth, remove if you dont need and change
  // the flags below
  attrs.colormap = XCreateColormap(d, root, vinfo.visual, AllocNone);
  attrs.background_pixel = 0;
  attrs.border_pixel = 0;

  // Window XCreateWindow(
  //     Display *display, Window parent,
  //     int x, int y, unsigned int width, unsigned int height, unsigned int
  //     border_width, int depth, unsigned int class, Visual *visual, unsigned
  //     long valuemask, XSetWindowAttributes *attributes
  // );
  Window overlay = XCreateWindow(
      d, root, 0, 0, 600, 600, 0, vinfo.depth, InputOutput, vinfo.visual,
      CWOverrideRedirect | CWColormap | CWBackPixel | CWBorderPixel, &attrs);

  XRectangle rect;
  XserverRegion region = XFixesCreateRegion(d, &rect, 1);
  XFixesSetWindowShapeRegion(d, overlay, ShapeInput, 0, 0, region);
  XFixesDestroyRegion(d, region);

  XMapWindow(d, overlay);

  cairo_surface_t *surf =
      cairo_xlib_surface_create(d, overlay, vinfo.visual, 600, 600);
  cairo_t *cr = cairo_create(surf);

  int good = 1;
  GifFileType *gif = DGifOpenFileName("loop.gif", &good);
  good &= (bool)gif;
  if (good) {
    DGifSlurp(gif);
  }

  std::cout << "Opened .gif with width/height = " << gif->SWidth << " "
            << gif->SHeight << std::endl;

  std::cout << (int)gif->SavedImages[0].RasterBits[0] << std::endl;
  int frame = 0;
  if (good) {
    for (auto Index = 0; Index < 1000; ++Index) {
      auto &Image = gif->SavedImages[frame];
      if(Image.ExtensionBlockCount) {
        std::cout << frame << " " << (int)Image.ExtensionBlockCount << "\n";
      }
      for (auto X = 0; X < gif->SWidth; ++X) {
        for (auto Y = 0; Y < gif->SHeight; ++Y) {
          auto Byte = Image.RasterBits[Y * gif->SWidth + X];
          auto Color = gif->SColorMap->Colors[Byte];
          cairo_set_source_rgba(cr, Color.Red / (double)255, Color.Green / (double)255, Color.Blue / (double)255, 1.0);
          cairo_rectangle(cr, X, Y, 1, 1);
          cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
          cairo_fill(cr);
        }
      }
      XFlush(d);
      frame = (frame + 1) % gif->ImageCount;
      std::this_thread::sleep_for(std::chrono::milliseconds(40));
    }

    // show the window for 10 seconds
    std::this_thread::sleep_for(std::chrono::milliseconds(10000));
  }

  cairo_destroy(cr);
  cairo_surface_destroy(surf);

  XUnmapWindow(d, overlay);
  XCloseDisplay(d);
  return 0;
}