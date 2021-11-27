{******************************************************************************}
{* This file is part of SAS.Planet project.                                   *}
{*                                                                            *}
{* Copyright (C) 2007-2021, SAS.Planet development team.                      *}
{*                                                                            *}
{* SAS.Planet is free software: you can redistribute it and/or modify         *}
{* it under the terms of the GNU General Public License as published by       *}
{* the Free Software Foundation, either version 3 of the License, or          *}
{* (at your option) any later version.                                        *}
{*                                                                            *}
{* SAS.Planet is distributed in the hope that it will be useful,              *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of             *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the               *}
{* GNU General Public License for more details.                               *}
{*                                                                            *}
{* You should have received a copy of the GNU General Public License          *}
{* along with SAS.Planet. If not, see <http://www.gnu.org/licenses/>.         *}
{*                                                                            *}
{* https://github.com/sasgis/sas.planet.src                                   *}
{******************************************************************************}

unit u_ImageLineProvider;

interface

uses
  Types,
  t_Bitmap32,
  i_InternalPerformanceCounter,
  i_NotifierOperation,
  i_Bitmap32Static,
  i_Projection,
  i_GeometryProjected,
  i_ImageLineProvider,
  i_BitmapTileProvider,
  u_BaseInterfacedObject;

type
  TImageLineProviderAbstract = class(TBaseInterfacedObject, IImageLineProvider)
  private
    FPrepareDataCounter: IInternalPerformanceCounter;
    FGetLineCounter: IInternalPerformanceCounter;

    FImageProvider: IBitmapTileProvider;
    FPolygon: IGeometryProjectedPolygon;
    FMapRect: TRect;
    FBgColor: TColor32;
    FBytesPerPixel: Integer;

    FProjection: IProjection;
    FPreparedTileRect: TRect;
    FPreparedMapRect: TRect;
    FPreparedData: array of Pointer;

    FTilePixArray: array of TColor32;

    function GetLocalLine(ALine: Integer): Pointer;
    procedure AddTile(
      const ABitmap: IBitmap32Static;
      const ATile: TPoint
    );
    procedure PrepareBufferMem(ARect: TRect);
    procedure ClearBuffer;
    function GetMapRectForLine(ALine: Integer): TRect;
    procedure PrepareBufferData(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AMapRect: TRect
    );
  protected
    procedure PreparePixleLine(
      ASource: PColor32;
      ATarget: Pointer;
      ACount: Integer
    ); virtual; abstract;
  private
    function GetImageSize: TPoint;
    function GetBytesPerPixel: Integer;
    function GetLine(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      ALine: Integer
    ): Pointer;
  public
    constructor Create(
      const APrepareDataCounter: IInternalPerformanceCounter;
      const AGetLineCounter: IInternalPerformanceCounter;
      const AImageProvider: IBitmapTileProvider;
      const APolygon: IGeometryProjectedPolygon;
      const AMapRect: TRect;
      const ABgColor: TColor32;
      const ABytesPerPixel: Integer
    );
    destructor Destroy; override;
  end;

  TImageLineProviderNoAlfa = class(TImageLineProviderAbstract)
  public
    constructor Create(
      const APrepareDataCounter: IInternalPerformanceCounter;
      const AGetLineCounter: IInternalPerformanceCounter;
      const AImageProvider: IBitmapTileProvider;
      const APolygon: IGeometryProjectedPolygon;
      const AMapRect: TRect;
      const ABgColor: TColor32
    );
  end;

  TImageLineProviderWithAlfa = class(TImageLineProviderAbstract)
  public
    constructor Create(
      const APrepareDataCounter: IInternalPerformanceCounter;
      const AGetLineCounter: IInternalPerformanceCounter;
      const AImageProvider: IBitmapTileProvider;
      const APolygon: IGeometryProjectedPolygon;
      const AMapRect: TRect;
      const ABgColor: TColor32
    );
  end;

  TImageLineProviderRGB = class(TImageLineProviderNoAlfa)
  protected
    procedure PreparePixleLine(
      ASource: PColor32;
      ATarget: Pointer;
      ACount: Integer
    ); override;
  end;

  TImageLineProviderBGR = class(TImageLineProviderNoAlfa)
  protected
    procedure PreparePixleLine(
      ASource: PColor32;
      ATarget: Pointer;
      ACount: Integer
    ); override;
  end;

  TImageLineProviderRGBA = class(TImageLineProviderWithAlfa)
  protected
    procedure PreparePixleLine(
      ASource: PColor32;
      ATarget: Pointer;
      ACount: Integer
    ); override;
  end;

  TImageLineProviderBGRA = class(TImageLineProviderWithAlfa)
  protected
    procedure PreparePixleLine(
      ASource: PColor32;
      ATarget: Pointer;
      ACount: Integer
    ); override;
  end;

implementation

uses
  Math,
  t_GeoTypes,
  u_GeoFunc,
  u_TileIteratorByRect;

{ TImageLineProviderAbstract }

constructor TImageLineProviderAbstract.Create(
  const APrepareDataCounter: IInternalPerformanceCounter;
  const AGetLineCounter: IInternalPerformanceCounter;
  const AImageProvider: IBitmapTileProvider;
  const APolygon: IGeometryProjectedPolygon;
  const AMapRect: TRect;
  const ABgColor: TColor32;
  const ABytesPerPixel: Integer
);
begin
  Assert(Assigned(AImageProvider));
  Assert(AImageProvider.Projection.CheckPixelRect(AMapRect));
  inherited Create;
  FPrepareDataCounter := APrepareDataCounter;
  FGetLineCounter := AGetLineCounter;
  FImageProvider := AImageProvider;
  FPolygon := APolygon;
  FMapRect := AMapRect;
  FBgColor := ABgColor;
  FBytesPerPixel := ABytesPerPixel;

  FProjection := FImageProvider.Projection;
  SetLength(FTilePixArray, 256);
end;

destructor TImageLineProviderAbstract.Destroy;
begin
  ClearBuffer;
  inherited;
end;

procedure TImageLineProviderAbstract.AddTile(
  const ABitmap: IBitmap32Static;
  const ATile: TPoint
);
var
  I, J: Integer;
  VTileMapRect: TRect;
  VTileSize: TPoint;
  VCopyRectSize: TPoint;
  VCopyMapRect: TRect;
  VCopyRectAtSource: TRect;
  VCopyRectAtTarget: TRect;
  VSourceLine: PColor32;
  VPixelPoint: TDoublePoint;
  VCheckPixelInPoly: Boolean;
begin
  Assert(Assigned(ABitmap));
  Assert(PtInRect(FPreparedTileRect, ATile));

  VTileMapRect := FProjection.TilePos2PixelRect(ATile);
  VTileSize := ABitmap.Size;
  Assert(IsPointsEqual(VTileSize, RectSize(VTileMapRect)));

  IntersectRect(VCopyMapRect, VTileMapRect, FPreparedMapRect);

  VCopyRectSize := RectSize(VCopyMapRect);
  VCopyRectAtTarget := RectMove(VCopyMapRect, FPreparedMapRect.TopLeft);
  VCopyRectAtSource := RectMove(VCopyMapRect, VTileMapRect.TopLeft);

  VCheckPixelInPoly := False;
  if FPolygon <> nil then begin
    VCheckPixelInPoly := FPolygon.IsRectIntersectPolygon( DoubleRect(VCopyMapRect) );
  end;

  if VCheckPixelInPoly and (Length(FTilePixArray) < VCopyRectSize.X) then begin
    // This should happen only if we work with tiles more then 256x256 pix
    SetLength(FTilePixArray, VCopyRectSize.X);
  end;

  for I := 0 to VCopyRectSize.Y - 1 do begin
    VSourceLine := @ABitmap.Data[VCopyRectAtSource.Left + (I + VCopyRectAtSource.Top) * VTileSize.X];

    // Fill pixels out of Poligon with Background color
    if VCheckPixelInPoly then begin

      // Copy source line into temporary buffer since we can't modify the source
      Move(VSourceLine^, FTilePixArray[0], VCopyRectSize.X * SizeOf(TColor32));

      for J := 0 to VCopyRectSize.X - 1 do begin
        VPixelPoint.X := VCopyMapRect.Left + J;
        VPixelPoint.Y := VCopyMapRect.Top + I;
        if not FPolygon.IsPointInPolygon(VPixelPoint) then begin
          FTilePixArray[J] := FBgColor;
        end;
      end;

      VSourceLine := @FTilePixArray[0];
    end;

    PreparePixleLine(
      VSourceLine,
      Pointer(Cardinal(FPreparedData[I + VCopyRectAtTarget.Top]) + Cardinal(VCopyRectAtTarget.Left * FBytesPerPixel)),
      VCopyRectSize.X
    );
  end;
end;

procedure TImageLineProviderAbstract.ClearBuffer;
var
  i: Integer;
begin
  for i := 0 to Length(FPreparedData) - 1 do begin
    if FPreparedData[i] <> nil then begin
      FreeMem(FPreparedData[i]);
      FPreparedData[i] := nil;
    end;
  end;
  FPreparedData := nil;
end;

function TImageLineProviderAbstract.GetBytesPerPixel: Integer;
begin
  Result := FBytesPerPixel;
end;

function TImageLineProviderAbstract.GetImageSize: TPoint;
begin
  Result := RectSize(FMapRect);
end;

function TImageLineProviderAbstract.GetLine(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  ALine: Integer
): Pointer;
var
  VMapLine: Integer;
  VContext: TInternalPerformanceCounterContext;
begin
  Assert(ALine >= 0);
  VMapLine := FMapRect.Top + ALine;
  Assert(VMapLine < FMapRect.Bottom);
  Assert(VMapLine >= FMapRect.Top);
  if not IsRectEmpty(FPreparedMapRect) then begin
    if (VMapLine < FPreparedMapRect.Top) or (VMapLine >= FPreparedMapRect.Bottom) then begin
      FPreparedMapRect := Rect(0, 0, 0, 0);
    end;
  end;

  if IsRectEmpty(FPreparedMapRect) then begin
    VContext := FPrepareDataCounter.StartOperation;
    try
      FPreparedMapRect := GetMapRectForLine(ALine);
      PrepareBufferData(AOperationID, ACancelNotifier, FPreparedMapRect);
    finally
      FPrepareDataCounter.FinishOperation(VContext);
    end;
  end;
  VContext := FGetLineCounter.StartOperation;
  try
    Result := GetLocalLine(ALine);
  finally
    FGetLineCounter.FinishOperation(VContext);
  end;
end;

function TImageLineProviderAbstract.GetLocalLine(ALine: Integer): Pointer;
var
  VMapLine: Integer;
begin
  Assert(ALine >= 0);
  VMapLine := FMapRect.Top + ALine;
  Assert(VMapLine < FMapRect.Bottom);
  Assert(VMapLine >= FPreparedMapRect.Top);
  Assert(VMapLine < FPreparedMapRect.Bottom);
  Result := FPreparedData[VMapLine - FPreparedMapRect.Top];
end;

procedure TImageLineProviderAbstract.PrepareBufferData(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AMapRect: TRect
);
var
  VTile: TPoint;
  VIterator: TTileIteratorByRectRecord;
begin
  PrepareBufferMem(AMapRect);
  FPreparedTileRect := FProjection.PixelRect2TileRect(AMapRect);
  VIterator.Init(FPreparedTileRect);
  while VIterator.Next(VTile) do begin
    AddTile(
      FImageProvider.GetTile(AOperationID, ACancelNotifier, VTile),
      VTile
    );
  end;
end;

procedure TImageLineProviderAbstract.PrepareBufferMem(ARect: TRect);
var
  VLinesExists: Integer;
  VLinesNeed: Integer;
  VWidth: Integer;
  i: Integer;
begin
  VWidth := ARect.Right - ARect.Left;
  VLinesNeed := ARect.Bottom - ARect.Top;
  VLinesExists := Length(FPreparedData);
  if VLinesExists < VLinesNeed then begin
    SetLength(FPreparedData, VLinesNeed);
    for i := VLinesExists to VLinesNeed - 1 do begin
      GetMem(FPreparedData[i], (VWidth + 1) * FBytesPerPixel);
    end;
  end;
end;

function TImageLineProviderAbstract.GetMapRectForLine(ALine: Integer): TRect;
var
  VMapLine: Integer;
  VTilePos: TPoint;
  VPixelRect: TRect;
begin
  Assert(ALine >= 0);
  VMapLine := FMapRect.Top + ALine;
  Assert(VMapLine < FMapRect.Bottom);
  VTilePos := PointFromDoublePoint(FProjection.PixelPos2TilePosFloat(Point(FMapRect.Left, VMapLine)), prToTopLeft);
  VPixelRect := FProjection.TilePos2PixelRect(VTilePos);
  Result := Rect(FMapRect.Left, VPixelRect.Top, FMapRect.Right, VPixelRect.Bottom);
end;

{ TImageLineProviderNoAlfa }

constructor TImageLineProviderNoAlfa.Create(
  const APrepareDataCounter: IInternalPerformanceCounter;
  const AGetLineCounter: IInternalPerformanceCounter;
  const AImageProvider: IBitmapTileProvider;
  const APolygon: IGeometryProjectedPolygon;
  const AMapRect: TRect;
  const ABgColor: TColor32
);
begin
  inherited Create(
    APrepareDataCounter,
    AGetLineCounter,
    AImageProvider,
    APolygon,
    AMapRect,
    ABgColor,
    3
  );
end;

{ TImageLineProviderWithAlfa }

constructor TImageLineProviderWithAlfa.Create(
  const APrepareDataCounter: IInternalPerformanceCounter;
  const AGetLineCounter: IInternalPerformanceCounter;
  const AImageProvider: IBitmapTileProvider;
  const APolygon: IGeometryProjectedPolygon;
  const AMapRect: TRect;
  const ABgColor: TColor32
);
begin
  inherited Create(
    APrepareDataCounter,
    AGetLineCounter,
    AImageProvider,
    APolygon,
    AMapRect,
    ABgColor,
    4
  );
end;

type
  TBGR = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;

  TRGB = packed record
    R: Byte;
    G: Byte;
    B: Byte;
  end;

  TRGBA = packed record
    R: Byte;
    G: Byte;
    B: Byte;
    A: Byte;
  end;



{ TImageLineProviderRGB }

procedure TImageLineProviderRGB.PreparePixleLine(
  ASource: PColor32;
  ATarget: Pointer;
  ACount: Integer
);
var
  i: Integer;
  VSource: PColor32Entry;
  VTarget: ^TRGB;
begin
  Assert(Assigned(ASource));
  VSource := PColor32Entry(ASource);
  VTarget := ATarget;
  for i := 0 to ACount - 1 do begin
    VTarget.B := VSource.B;
    VTarget.G := VSource.G;
    VTarget.R := VSource.R;
    Inc(VSource);
    Inc(VTarget);
  end;
end;

{ TImageLineProviderBGR }

procedure TImageLineProviderBGR.PreparePixleLine(
  ASource: PColor32;
  ATarget: Pointer;
  ACount: Integer
);
var
  i: Integer;
  VSource: PColor32Entry;
  VTarget: ^TBGR;
begin
  Assert(Assigned(ASource));
  VSource := PColor32Entry(ASource);
  VTarget := ATarget;
  for i := 0 to ACount - 1 do begin
    VTarget.B := VSource.B;
    VTarget.G := VSource.G;
    VTarget.R := VSource.R;
    Inc(VSource);
    Inc(VTarget);
  end;
end;

{ TImageLineProviderARGB }

procedure TImageLineProviderRGBA.PreparePixleLine(
  ASource: PColor32;
  ATarget: Pointer;
  ACount: Integer
);
var
  i: Integer;
  VSource: PColor32Entry;
  VTarget: ^TRGBA;
begin
  Assert(Assigned(ASource));
  VSource := PColor32Entry(ASource);
  VTarget := ATarget;
  for i := 0 to ACount - 1 do begin
    VTarget.B := VSource.B;
    VTarget.G := VSource.G;
    VTarget.R := VSource.R;
    VTarget.A := VSource.A;
    Inc(VSource);
    Inc(VTarget);
  end;
end;

{ TImageLineProviderBGRA }

procedure TImageLineProviderBGRA.PreparePixleLine(
  ASource: PColor32;
  ATarget: Pointer;
  ACount: Integer
);
begin
  Assert(Assigned(ASource));
  Move(ASource^, ATarget^, ACount * SizeOf(ASource^));
end;

end.
