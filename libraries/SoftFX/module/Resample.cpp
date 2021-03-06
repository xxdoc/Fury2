/*
SoftFX (Software graphics manipulation library)
Copyright (C) 2003 Kevin Gadd

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include "../header/SoftFX Main.hpp"
#include "../header/Blend.hpp"

ScalerFunction *DefaultSampleFunction;

//
//  ISSUE: Pixel coordinates are weighted at the top-left instead of the pixel 'center'.
//  SYMPTOM(S): Resampling will often show inconsistencies between left/right and top/bottom.
//
void SampleRow_Bilinear(Image *Source, int X, int Y, int XW, int YW, int XI, int YI, int XWI, int YWI, int Count, Pixel *Dest) {
int xw, yw;
int i;
Byte w[4];
short b, g, r, a;
Pixel S;
AlphaLevel *Level;
    ImageLockManager ilSource(lockingMode, Source);
    if (!ilSource.performUnlock()) return;
    X = X;
    Y = Y;
    XW = XW;
    YW = YW;
    for (i = 0; i < Count; i++) {
      if (XW >= 65535) {
        X += (XW / 65535);
        XW = XW % 65535;
      }
      if (XW < 0) {
        X -= ((-XW) / 65535) + 1;
        XW = 65535 - (-XW % 65535);
      }
      if (YW >= 65535) {
        Y += (YW / 65535);
        YW = YW % 65535;
      }
      if (YW < 0) {
        Y -= ((-YW) / 65535) + 1;
        YW = 65535 - (-YW % 65535);
      }

      if ((XW) || (YW)) {

        xw = XW / 256;
        yw = YW / 256;
        w[1] = AlphaLookup(xw, yw ^ 0xFF);
        w[2] = AlphaLookup(xw ^ 0xFF, yw);
        w[3] = AlphaLookup(xw, yw);
        w[0] = (w[1] + w[2] + w[3]) ^ 0xFF;

        Level = AlphaLevelLookup(w[0]);
        S = Source->getPixelClipNO(X, Y);
        b = Level->V[S[::Blue]];
        g = Level->V[S[::Green]];
        r = Level->V[S[::Red]];
        a = Level->V[S[::Alpha]];

        Level = AlphaLevelLookup(w[1]);
        S = Source->getPixelClipNO(X+1, Y);
        b += Level->V[S[::Blue]];
        g += Level->V[S[::Green]];
        r += Level->V[S[::Red]];
        a += Level->V[S[::Alpha]];

        Level = AlphaLevelLookup(w[2]);
        S = Source->getPixelClipNO(X, Y+1);
        b += Level->V[S[::Blue]];
        g += Level->V[S[::Green]];
        r += Level->V[S[::Red]];
        a += Level->V[S[::Alpha]];

        Level = AlphaLevelLookup(w[3]);
        S = Source->getPixelClipNO(X+1, Y+1);    

        (*Dest)[::Blue] = ClipByteHigh(b + Level->V[S[::Blue]]);
        (*Dest)[::Green] = ClipByteHigh(g + Level->V[S[::Green]]);
        (*Dest)[::Red] = ClipByteHigh(r + Level->V[S[::Red]]);
        (*Dest)[::Alpha] = ClipByteHigh(a + Level->V[S[::Alpha]]);

      } else {

        *Dest = Source->getPixelClip(X, Y);

      }

      Dest++;

      X += XI;
      Y += YI;
      XW += XWI;
      YW += YWI;
    }
    return;
}

void SampleRow_Linear(Image *Source, int X, int Y, int XW, int YW, int XI, int YI, int XWI, int YWI, int Count, Pixel *Dest) {
int i;
  ImageLockManager ilSource(lockingMode, Source);
  if (!ilSource.performUnlock()) return;
  {
    int wmax = (65535 / Count);
    if ((XI == 1) && (YI == 0) && (XWI < wmax) && (YWI < wmax)) {
      i = Count;
      while (i--) {
        *Dest++ = Source->getPixelClipNO(X, Y);
        ++X;
      }
      return;
    } else if ((XI == -1) && (YI == 0) && (XWI < wmax) && (YWI < wmax)) {
      i = Count;
      X += Count - 1;
      while (i--) {
        *Dest++ = Source->getPixelClipNO(X, Y);
        --X;
      }
      return;
    }
  }
  for (i = 0; i < Count; i++) {
    if (XW >= 65535) {
      X += (XW / 65535);
      XW = XW % 65535;
    }
    if (XW < 0) {
      X -= ((-XW) / 65535) + 1;
      XW = 65535 - (-XW % 65535);
    }
    if (YW >= 65535) {
      Y += (YW / 65535);
      YW = YW % 65535;
    }
    if (YW < 0) {
      Y -= ((-YW) / 65535) + 1;
      YW = 65535 - (-YW % 65535);
    }

    *Dest = Source->getPixelClipNO(X, Y);
    Dest++;

    X += XI;
    Y += YI;
    XW += XWI;
    YW += YWI;
  }
  return;
}

void SampleRow_Bilinear_Rolloff(Image *Source, int X, int Y, int XW, int YW, int XI, int YI, int XWI, int YWI, int Count, Pixel *Dest) {
int xw, yw;
int i;
Byte w[4];
short b, g, r, a;
Pixel S;
AlphaLevel *Level;
    ImageLockManager ilSource(lockingMode, Source);
    if (!ilSource.performUnlock()) return;
    X = X;
    Y = Y;
    XW = XW;
    YW = YW;
    for (i = 0; i < Count; i++) {
      if (XW >= 65535) {
        X += (XW / 65535);
        XW = XW % 65535;
      }
      if (XW < 0) {
        X -= ((-XW) / 65535) + 1;
        XW = 65535 - (-XW % 65535);
      }
      if (YW >= 65535) {
        Y += (YW / 65535);
        YW = YW % 65535;
      }
      if (YW < 0) {
        Y -= ((-YW) / 65535) + 1;
        YW = 65535 - (-YW % 65535);
      }

      if ((XW) || (YW)) {

        xw = XW / 256;
        yw = YW / 256;
        w[1] = AlphaLookup(xw, yw ^ 0xFF);
        w[2] = AlphaLookup(xw ^ 0xFF, yw);
        w[3] = AlphaLookup(xw, yw);
        w[0] = (w[1] + w[2] + w[3]) ^ 0xFF;

        Level = AlphaLevelLookup(w[0]);
        S = Source->getPixelRolloffNO(X, Y);
        b = Level->V[S[::Blue]];
        g = Level->V[S[::Green]];
        r = Level->V[S[::Red]];
        a = Level->V[S[::Alpha]];

        Level = AlphaLevelLookup(w[1]);
        S = Source->getPixelRolloffNO(X+1, Y);
        b += Level->V[S[::Blue]];
        g += Level->V[S[::Green]];
        r += Level->V[S[::Red]];
        a += Level->V[S[::Alpha]];

        Level = AlphaLevelLookup(w[2]);
        S = Source->getPixelRolloffNO(X, Y+1);
        b += Level->V[S[::Blue]];
        g += Level->V[S[::Green]];
        r += Level->V[S[::Red]];
        a += Level->V[S[::Alpha]];

        Level = AlphaLevelLookup(w[3]);
        S = Source->getPixelRolloffNO(X+1, Y+1);    

        (*Dest)[::Blue] = ClipByteHigh(b + Level->V[S[::Blue]]);
        (*Dest)[::Green] = ClipByteHigh(g + Level->V[S[::Green]]);
        (*Dest)[::Red] = ClipByteHigh(r + Level->V[S[::Red]]);
        (*Dest)[::Alpha] = ClipByteHigh(a + Level->V[S[::Alpha]]);

      } else {

        *Dest = Source->getPixelRolloffNO(X, Y);

      }

      Dest++;

      X += XI;
      Y += YI;
      XW += XWI;
      YW += YWI;
    }
    return;
}

void SampleRow_Linear_Rolloff(Image *Source, int X, int Y, int XW, int YW, int XI, int YI, int XWI, int YWI, int Count, Pixel *Dest) {
int i;
int pX, pY;
bool c = false;
    ImageLockManager ilSource(lockingMode, Source);
    if (!ilSource.performUnlock()) return;
    X = X;
    Y = Y;
    XW = XW;
    YW = YW;
    for (i = 0; i < Count; i++) {
      if (XW >= 65535) {
        X += (XW / 65535);
        XW = XW % 65535;
      }
      if (XW < 0) {
        X -= ((-XW) / 65535) + 1;
        XW = 65535 - (-XW % 65535);
      }
      if (YW >= 65535) {
        Y += (YW / 65535);
        YW = YW % 65535;
      }
      if (YW < 0) {
        Y -= ((-YW) / 65535) + 1;
        YW = 65535 - (-YW % 65535);
      }

      pX = X;
      pY = Y;
      c = false;
      if (pX < 0) {
        pX = 0;
        c = true;
      } else if (pX >= Source->Width) {
        pX = Source->Width - 1;
        c = true;
      }
      if (pY < 0) {
        pY = 0;
        c = true;
      } else if (pY >= Source->Height) {
        pY = Source->Height - 1;
        c = true;
      }
      if (c) { 
        *Dest = Source->getPixelNO(pX, pY);
        (*Dest)[::Alpha] = 0;
      } else {
        *Dest = Source->getPixelNO(pX, pY);
      }
      Dest++;

      X += XI;
      Y += YI;
      XW += XWI;
      YW += YWI;
    }
    return;
}

void SampleRow_Bilinear_Wrap(Image *Source, int X, int Y, int XW, int YW, int XI, int YI, int XWI, int YWI, int Count, Pixel *Dest) {
int xw, yw;
int i;
Byte w[4];
short b, g, r, a;
Pixel S;
AlphaLevel *Level;
    ImageLockManager ilSource(lockingMode, Source);
    if (!ilSource.performUnlock()) return;
    X = X;
    Y = Y;
    XW = XW;
    YW = YW;
    for (i = 0; i < Count; i++) {
      if (XW >= 65535) {
        X += (XW / 65535);
        XW = XW % 65535;
      }
      if (XW < 0) {
        X -= ((-XW) / 65535) + 1;
        XW = 65535 - (-XW % 65535);
      }
      if (YW >= 65535) {
        Y += (YW / 65535);
        YW = YW % 65535;
      }
      if (YW < 0) {
        Y -= ((-YW) / 65535) + 1;
        YW = 65535 - (-YW % 65535);
      }

      if ((XW) || (YW)) {

        xw = XW / 256;
        yw = YW / 256;
        w[1] = AlphaLookup(xw, yw ^ 0xFF);
        w[2] = AlphaLookup(xw ^ 0xFF, yw);
        w[3] = AlphaLookup(xw, yw);
        w[0] = (w[1] + w[2] + w[3]) ^ 0xFF;

        Level = AlphaLevelLookup(w[0]);
        S = Source->getPixelWrap(X, Y);
        b = Level->V[S[::Blue]];
        g = Level->V[S[::Green]];
        r = Level->V[S[::Red]];
        a = Level->V[S[::Alpha]];

        Level = AlphaLevelLookup(w[1]);
        S = Source->getPixelWrap(X+1, Y);
        b += Level->V[S[::Blue]];
        g += Level->V[S[::Green]];
        r += Level->V[S[::Red]];
        a += Level->V[S[::Alpha]];

        Level = AlphaLevelLookup(w[2]);
        S = Source->getPixelWrap(X, Y+1);
        b += Level->V[S[::Blue]];
        g += Level->V[S[::Green]];
        r += Level->V[S[::Red]];
        a += Level->V[S[::Alpha]];

        Level = AlphaLevelLookup(w[3]);
        S = Source->getPixelWrap(X+1, Y+1);    

        (*Dest)[::Blue] = ClipByteHigh(b + Level->V[S[::Blue]]);
        (*Dest)[::Green] = ClipByteHigh(g + Level->V[S[::Green]]);
        (*Dest)[::Red] = ClipByteHigh(r + Level->V[S[::Red]]);
        (*Dest)[::Alpha] = ClipByteHigh(a + Level->V[S[::Alpha]]);

      } else {

        *Dest = Source->getPixelWrap(X, Y);

      }

      Dest++;

      X += XI;
      Y += YI;
      XW += XWI;
      YW += YWI;
    }
    return;
}

void SampleRow_Linear_Wrap(Image *Source, int X, int Y, int XW, int YW, int XI, int YI, int XWI, int YWI, int Count, Pixel *Dest) {
int i;
    ImageLockManager ilSource(lockingMode, Source);
    if (!ilSource.performUnlock()) return;
    X = X;
    Y = Y;
    XW = XW;
    YW = YW;
    for (i = 0; i < Count; i++) {
      if (XW >= 65535) {
        X += (XW / 65535);
        XW = XW % 65535;
      }
      if (XW < 0) {
        X -= ((-XW) / 65535) + 1;
        XW = 65535 - (-XW % 65535);
      }
      if (YW >= 65535) {
        Y += (YW / 65535);
        YW = YW % 65535;
      }
      if (YW < 0) {
        Y -= ((-YW) / 65535) + 1;
        YW = 65535 - (-YW % 65535);
      }

      *Dest = Source->getPixelWrap(X, Y);
      Dest++;

      X += XI;
      Y += YI;
      XW += XWI;
      YW += YWI;
    }
    return;
}

Export int GetBilinearScaler() {
  return (int)SampleRow_Bilinear_Rolloff;
}

Export int GetLinearScaler() {
  return (int)SampleRow_Linear_Rolloff;
}

Export int GetBilinearClampScaler() {
  return (int)SampleRow_Bilinear;
}

Export int GetLinearClampScaler() {
  return (int)SampleRow_Linear;
}

Export int GetBilinearWrapScaler() {
  return (int)SampleRow_Bilinear_Wrap;
}

Export int GetLinearWrapScaler() {
  return (int)SampleRow_Linear_Wrap;
}