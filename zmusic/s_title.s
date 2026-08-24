;------------------------------------------------------------------------------
; Assemble with HAS060.X
;------------------------------------------------------------------------------
; filename:    s_title.s
; version:     1. 0. 0
; author:      SEN::DAC
; Description: シーン：タイトル
;------------------------------------------------------------------------------
                .include iocscall.mac
                .include doscall.mac
                .include ./input/input.h
                .include ./se_music/se_music.h

;------------------------------------------------------------------------------
                .data
                .even
;------------------------------------------------------------------------------
bmfn_gr00:      .dc.b   'image/title.bmp',0       ; 読み込むBMP画像ファイル名(GR)
bmfn_sp00:      .dc.b   'image/sp00.bmp',0        ; 読み込むBMP画像ファイル名(SP)
Zm_FileName00:  .dc.b   'zmd/bgm00.zmd',0         ; 読み込むZMD音楽ファイル名

;------------------------------------------------------------------------------
                .text
                .even
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; シーン - タイトル 初期化
;------------------------------------------------------------------------------
s_title_ini::

        ; GR画面に背景を描画
        lea.l   bmfn_gr00,a0            ; ロードするBMPファイル名
        lea.l   pal00,a1                ; パレットを格納するアドレス
        jbsr    D0123A01_LoadBmpPal16   ; 16色BMPからパレットをロード

        lea.l   bmfn_gr00,a0            ; ロードするBMPファイル名
        lea.l   SrcImgArray,a1          ; 画像を格納するアドレス
        jbsr    D0123A01_LoadBmpImage16 ; 画像をロード

        lea.l   SrcImgArray,a0          ; src (BMP)
        lea.l   DstImgArray,a1          ; dst (GR)
        move.w  #384*256/2,d0           ; ループ回数(W*H/2)
        jbsr    D01A01_BmpToGR          ; BMP配列 → GR配列 変換

        lea.l   DstImgArray,a2          ; GR配列の先頭アドレス
        lea.l   $C00000,a3              ; GR0のVRAM先頭アドレス
        move.w  #384,d3                 ; 画像の横幅
        move.w  #256-1,d4               ; 画像の縦幅-1
        jbsr    D01234A0123_GrDraw      ; Gr-Vram書き込み

        lea.l   pal00,a0                ; 登録元データの先頭アドレス
        lea.l   $E82000,a1              ; 登録先パレットの先頭アドレス(PB直接指定)
        jbsr    D012A01_SetPal16        ; パレット登録

        ; スプライト表示 注:GRより後に描かないとSPが先に表示されてしまう
        lea.l   bmfn_sp00,a0            ; ロードするBMPファイル名
        lea.l   pal00,a1                ; パレットを格納するアドレス
        jbsr    D0123A01_LoadBmpPal16   ; 16色BMPからパレットをロード

        lea.l   bmfn_sp00,a0            ; ロードするBMPファイル名
        lea.l   SrcImgArray,a1          ; 画像を格納するアドレス
        jbsr    D0123A01_LoadBmpImage16 ; 画像をロード

        lea.l   SrcImgArray,a0          ; src (BMP配列)
        lea.l   $EB8000,a1              ; dst (PCG直接)
        move.l  #1,d0                   ; PCG番号(0～255)dstがramの場合は0を指定する
        jbsr    D01A01_BmpToPcg         ; BMP配列(RAM) → PCG配列(RAM/PCG) 変換

        move.l  #0,d0                   ; 反転なし
        move.l  #1,d1                   ; パレットブロック(0～15)
        move.l  #1,d2                   ; PCG番号(0～255)
        jbsr    D0123Ax_MkSpPtc         ; パターンコード生成

        move.w  #1,d0                   ; 表示するスプライト番号(0 - 127)
        move.w  #16+128,d1              ; X座標(0-1023)画面左上から-16,-16が起点
        move.w  #16+128,d2              ; Y座標(0-1023)画面左上から-16,-16が起点
                                        ; パターンコードd3.lはそのまま渡す
        move.w  #3,d4                   ; プライオリティ(パラメータの名前と値をequするP.420)
        jbsr    D01234A0_PutSp          ; スプライトを表示 (_SP_REGST と同等の作用)

        lea.l   pal00,a0                ; 登録元データの先頭アドレス
        lea.l   $E82220,a1              ; 登録先パレットの先頭アドレス(PB直接指定)
        jbsr    D012A01_SetPal16        ; パレット登録

        ; ZMD 演奏開始
        lea.l   Zm_FileName00,a0        ; 引数：ファイル名を指すポインタ
        lea.l   Zm_LoadBuff00,a1        ; 引数：ロード先バッファを指すポインタ
        jbsr    D045A01_LoadZmd         ; ZMDファイルをロードしてバッファに格納
        clr.l   d2                      ; 引数：d2.l = データ総サイズ(0:即演奏(高速応答))
        ZMUSIC  _ZM_M_PLAY              ; $11 ZMDの演奏

        lea.l   s_title_run,a6          ; シーン実行処理へ
        rts

;------------------------------------------------------------------------------
; シーン - タイトル 実行
;------------------------------------------------------------------------------
s_title_run::

        ; Xキー(Aボタン)が押された瞬間か？
        move.w  #BTN_A__,d0             ; d0.w ボタン：Xキー(Aボタン)
        move.w  #BS_DOW,d1              ; d1.w 状態  ：押した瞬間
        jbsr    Input_1P_GetState       ; コントローラ n の入力情報を取得する
        tst.w   d0                      ; 0(非成立)か？
        beq     @f                      ; 0(非成立)なら飛ぶ

        ; 条件成立なら 効果音を鳴らす
        moveq.l #SE_ENTER,d2            ; 引数: ノート番号(カーソル決定)
        move.l  #$00_04_03,d3           ; 引数: 優先度_周波数_パン 各1バイト
        ZMUSIC  _ZM_SE_PLAY             ; ZMUSIC 登録済みADPCM効果音を再生

        ; 条件成立なら 次のシーンを設定
        lea.l   s_play_ini,a5           ; 次のシーンの初期化フェーズを設定
        lea.l   s_title_rel,a6          ; シーン解放処理へ
@@:
        move.w  #BTN_B__,d0             ; d0.w ボタン：Zキー(Bボタン)
        move.w  #BS_DOW,d1              ; d1.w 状態  ：押した瞬間
        jbsr    Input_1P_GetState       ; コントローラ n の入力情報を取得する
        tst.w   d0                      ; 0(非成立)か？
        beq     @f                      ; 0(非成立)なら飛ぶ
        lea.l   0,a5                    ; 次のシーンとしてNULLを指定する(アプリ終了)
        lea.l   s_title_rel,a6          ; シーン解放処理へ
@@:
        rts

;------------------------------------------------------------------------------
; シーン - タイトル 解放
;------------------------------------------------------------------------------
s_title_rel::

        lea.l   init_pal,a0             ; 引数：登録元データの先頭アドレス   設定値：ALL黒パレット
        lea.l   $E82000,a1              ; 引数：登録先パレットの先頭アドレス 設定値：GRパレット
        jbsr    D012A01_SetPal16        ; パレット登録

        lea.l   init_pal,a0             ; 引数：登録元データの先頭アドレス   設定値：ALL黒パレット
        lea.l   $E82220,a1              ; 引数：登録先パレットの先頭アドレス 設定値：SPパレット
        jbsr    D012A01_SetPal16        ; パレット登録

        move.l  #85,d2                  ; 引数：d2.l=1(遅)～85(速):フェードアウト
        ZMUSIC  _ZM_FADE                ; 演奏フェードイン/アウト
;       ZMUSIC  _ZM_M_STOP              ; 演奏停止

        movea.l a5,a6                   ; 次のシーンへ切り替え
        rts
