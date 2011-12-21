unit u_ThreadMapCombinePNG;

interface

uses
  Windows,
  Types,
  SysUtils,
  Classes,
  GR32,
  i_GlobalViewMainConfig,
  i_BitmapLayerProvider,
  i_LocalCoordConverterFactorySimpe,
  u_MapType,
  u_GeoFun,
  u_BmpUtil,
  t_GeoTypes,
  i_BitmapPostProcessingConfig,
  u_ResStrings,
  u_ThreadMapCombineBase,
  LibPNG;

type
  PArrayBGR = ^TArrayBGR;
  TArrayBGR = array [0..0] of TBGR;

  P256ArrayBGR = ^T256ArrayBGR;
  T256ArrayBGR = array[0..255] of PArrayBGR;

  TThreadMapCombinePNG = class(TThreadMapCombineBase)
  private
    FArray256BGR: P256ArrayBGR;
    sx, ex, sy, ey: integer;
    btmm: TCustomBitmap32;
    procedure ReadLineBMP(ALine: cardinal; LineRGB: png_bytep);
  protected
    procedure saveRECT; override;
  end;

implementation

uses
  gnugettext,
  i_LocalCoordConverter;

type
  sas_png_rw_io_ptr = ^sas_png_rw_io;
  sas_png_rw_io = record
    DestStream: TFileStream;
    DestBuffer: Pointer;
    DestBufferSize: Cardinal;
    BufferedDataSize: Cardinal;
  end;

procedure flash_dest_buffer(rw_io_ptr: sas_png_rw_io_ptr);
begin
  if rw_io_ptr^.BufferedDataSize > 0 then begin
    rw_io_ptr^.DestStream.WriteBuffer(rw_io_ptr^.DestBuffer^, rw_io_ptr^.BufferedDataSize);
    rw_io_ptr^.BufferedDataSize := 0;
  end;
end;

procedure sas_png_write_data(png_ptr: png_structp; data: png_bytep;
  data_length: png_size_t); cdecl;
var
  rw_io_ptr: sas_png_rw_io_ptr;
begin
  rw_io_ptr := sas_png_rw_io_ptr(png_ptr.io_ptr);
  if data_length >= rw_io_ptr^.DestBufferSize then begin // buffer is too small
    flash_dest_buffer(rw_io_ptr);
    rw_io_ptr^.DestStream.WriteBuffer(data^, data_length);
  end else if (rw_io_ptr^.BufferedDataSize + data_length) >= rw_io_ptr^.DestBufferSize then begin // buffer is full
    flash_dest_buffer(rw_io_ptr);
    CopyMemory(Pointer(Cardinal(rw_io_ptr^.DestBuffer) + rw_io_ptr^.BufferedDataSize), data, data_length);
    Inc(rw_io_ptr^.BufferedDataSize, data_length);
  end else begin // (rw_io_ptr^.BufferedDataSize + data_length) < rw_io_ptr^.DestBufferSize  // buffer is OK
    CopyMemory(Pointer(Cardinal(rw_io_ptr^.DestBuffer) + rw_io_ptr^.BufferedDataSize), data, data_length);
    Inc(rw_io_ptr^.BufferedDataSize, data_length);
  end;
end;

{ TThreadMapCombinePNG }

procedure TThreadMapCombinePNG.ReadLineBMP(ALine: cardinal; LineRGB: png_bytep);
var
  i, j, rarri, lrarri, p_x, p_y, Asx, Asy, Aex, Aey, starttile: integer;
  line: Integer;
  p: PColor32array;
  VConverter: ILocalCoordConverter;
begin
  line := ALine;
  if line < (256 - sy) then begin
    starttile := sy + line;
  end else begin
    starttile := (line - (256 - sy)) mod 256;
  end;
  if (starttile = 0) or (line = 0) then begin
    FTilesProcessed := line;
    ProgressFormUpdateOnProgress;
    p_y := (FCurrentPieceRect.Top + line) - ((FCurrentPieceRect.Top + line) mod 256);
    p_x := FCurrentPieceRect.Left - (FCurrentPieceRect.Left mod 256);
    lrarri := 0;
    rarri := 0;
    if line > (255 - sy) then begin
      Asy := 0;
    end else begin
      Asy := sy;
    end;
    if (p_y div 256) = (FCurrentPieceRect.Bottom div 256) then begin
      Aey := ey;
    end else begin
      Aey := 255;
    end;
    Asx := sx;
    Aex := 255;
    while p_x <= FCurrentPieceRect.Right do begin
      if not (RgnAndRgn(FPoly, p_x + 128, p_y + 128, false)) then begin
        btmm.Clear(FBackGroundColor);
      end else begin
        FLastTile := Point(p_x shr 8, p_y shr 8);
        VConverter := CreateConverterForTileImage(FLastTile);
        PrepareTileBitmap(btmm, VConverter, FBackGroundColor);
      end;
      if (p_x + 256) > FCurrentPieceRect.Right then begin
        Aex := ex;
      end;
      for j := Asy to Aey do begin
        p := btmm.ScanLine[j];
        rarri := lrarri;
        for i := Asx to Aex do begin
          CopyMemory(@FArray256BGR[j]^[rarri], Pointer(integer(p) + (i * 4)), 3);
          inc(rarri);
        end;
      end;
      lrarri := rarri;
      Asx := 0;
      inc(p_x, 256);
    end;
  end;
  CopyMemory(LineRGB, FArray256BGR^[starttile], (FCurrentPieceRect.Right - FCurrentPieceRect.Left) * 3);
end;

procedure TThreadMapCombinePNG.saveRECT;
const
  PNG_MAX_HEIGHT = 65536;
  PNG_MAX_WIDTH = 65536;
var
  iWidth, iHeight: integer;
  i,j: integer;
  png_ptr: png_structp;
  info_ptr: png_infop;
  prow: png_bytep;
  rw_io: sas_png_rw_io;
  SwapBuf: Byte;
begin
  sx := (FCurrentPieceRect.Left mod 256);
  sy := (FCurrentPieceRect.Top mod 256);
  ex := (FCurrentPieceRect.Right mod 256);
  ey := (FCurrentPieceRect.Bottom mod 256);

  iWidth := FMapPieceSize.X;
  iHeight := FMapPieceSize.y;

  if (iWidth >= PNG_MAX_WIDTH) or (iHeight >= PNG_MAX_HEIGHT) then begin
    raise Exception.Create(
      'Selected resolution is too big for PNG format!'+#13#10+
      'Widht = '+inttostr(iWidth) + ' (max = ' + IntToStr(PNG_MAX_WIDTH) + ')' + #13#10+
      'Height = '+inttostr(iHeight) + ' (max = ' + IntToStr(PNG_MAX_HEIGHT) + ')' + #13#10+
      'Try select smaller region to stitch in PNG or select other output format (ECW is the best).'
    );
  end;

  if not Init_LibPNG then begin
    raise Exception.Create( _('Initialization of LibPNG failed.') );
  end;

  rw_io.DestStream := TFileStream.Create(FCurrentFileName, fmCreate);
  rw_io.DestBufferSize := 64*1024; // 64k
  GetMem(rw_io.DestBuffer, rw_io.DestBufferSize);
  rw_io.BufferedDataSize := 0;
  try
    png_ptr := png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil);
    if Assigned(png_ptr) then begin
      info_ptr := png_create_info_struct(png_ptr);
    end else begin
      raise Exception.Create( _('LibPNG: Failed to Create PngStruct!') );
    end;
    if Assigned(info_ptr) then begin
      try
        png_set_write_fn(png_ptr, @rw_io, @sas_png_write_data, nil);

        // Write header (8 bit colour depth)
        png_set_IHDR(png_ptr, info_ptr, iWidth, iHeight, 8, PNG_COLOR_TYPE_RGB,
          PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

        png_write_info(png_ptr, info_ptr);

        // allocate row
        GetMem(prow, info_ptr.width * 3);

        GetMem(FArray256BGR, 256 * sizeof(P256ArrayBGR));
        for i := 0 to 255 do begin
          GetMem(FArray256BGR[i], (info_ptr.width + 1) * 3);
        end;
        try
          btmm := TCustomBitmap32.Create;
          try
            btmm.Width := 256;
            btmm.Height := 256;

            for i := 0 to info_ptr.height - 1 do begin
              ReadLineBMP(i, prow);

              // BGR to RGB swap
              for j := 0 to info_ptr.width - 1 do begin
                SwapBuf := PByte(Integer(prow) + j*3)^;
                PByte(Integer(prow) + j*3)^ := PByte(Integer(prow) + j*3 + 2)^;
                PByte(Integer(prow) + j*3 + 2)^ := SwapBuf;
              end;

              // write row
              png_write_row(png_ptr, prow);

              if CancelNotifier.IsOperationCanceled(OperationID) then begin
                Break;
              end;
            end;
          finally
            btmm.Free;
          end;
        finally
          for i := 0 to 255 do begin
            freemem(FArray256BGR[i], (iWidth + 1) * 3);
          end;
          freemem(FArray256BGR, 256 * ((iWidth + 1) * 3));

          // freeing row
          FreeMem(prow);

          // End write
          png_write_end(png_ptr, info_ptr);
        end;
      finally
        png_free_data(png_ptr, info_ptr, PNG_FREE_ALL);
        
        png_destroy_write_struct(@png_ptr, @info_ptr);
      end;
    end;
  finally
    flash_dest_buffer(@rw_io);
    FreeMem(rw_io.DestBuffer);
    rw_io.DestStream.Free;
  end;
end;

end.
