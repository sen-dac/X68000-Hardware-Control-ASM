;------------------------------------------------------------------------------
; Assemble with HAS060.X
;------------------------------------------------------------------------------
; filename:    main.s
; version:     1. 0. 0
; author:      SEN::DAC
; Description: グラフィック画面とスプライトの描画テスト メイン処理
;------------------------------------------------------------------------------
                .include doscall.mac
                .include iocscall.mac
                .include ./input/input.h
                .include ./itoa/itoa.h
                .include ./scene/s_title.h
                .include ./scene/s_play.h
                .include ./scene/s_end.h

;------------------------------------------------------------------------------
                .bss
                .even
;------------------------------------------------------------------------------
ssp_work:       .ds.l   1               ; ssp保存用

;------------------------------------------------------------------------------
                .text
                .even
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; メイン処理
;------------------------------------------------------------------------------
main:

; アプリケーション 初期化処理
main_init:
        clr.l   -(sp)                   ; スーパーバイザモード ON
        DOS     _SUPER                  ;
        addq.l  #4,sp                   ; sp戻し
        move.l  d0,ssp_work             ;

        moveq.l #_CRTMOD,d0             ; 画面モードの設定
        move.w  #4,d1                   ; 画面モードの番号 : 4 = 512*512*4
        trap    #15
        bsr     DxAx_crt384             ; 特殊画面モード(384*256)

        moveq.l #_G_CLR_ON,d0           ; 画面をクリアして表示をオンにする
        trap    #15

        moveq.l #_SP_INIT,d0            ; PCGをクリアする
        trap    #15

        moveq.l #_SP_ON,d0              ; スプライト表示をオンにする
        trap    #15

        ; グラフィック画面の描画テスト

        lea.l   init_pal,a0             ; 登録元データの先頭アドレス(ALL黒パレット)
        lea.l   $E82000,a1              ; 登録先パレットの先頭アドレス(PB直接指定)
        jbsr    D012A01_SetPal16        ; パレット登録

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

        ; スプライトの描画テスト
        ; グラフィック画面より後に描かないとスプライトが先に表示されてしまう

        lea.l   bmfn_sp00,a0            ; ロードするBMPファイル名
        lea.l   pal00,a1                ; パレットを格納するアドレス
        jbsr    D0123A01_LoadBmpPal16   ; 16色BMPからパレットをロード

        lea.l   pal00,a0                ; 登録元データの先頭アドレス
        lea.l   $E82220,a1              ; 登録先パレットの先頭アドレス(PB直接指定)
        jbsr    D012A01_SetPal16        ; パレット登録

        lea.l   bmfn_sp00,a0            ; ロードするBMPファイル名
        lea.l   SrcImgArray,a1          ; 画像を格納するアドレス
        jbsr    D0123A01_LoadBmpImage16 ; 画像をロード

        lea.l   SrcImgArray,a0          ; src (BMP配列)
        lea.l   DstImgArray,a1          ; dst (PCG配列)
        move.l  #0,d0                   ; PCG番号(0～255)dstがramの場合は0を指定する
        jbsr    D01A01_BmpToPcg         ; BMP配列(RAM) → PCG配列(RAM/PCG) 変換

        lea.l   DstImgArray,a0          ; src (PCG配列)
        lea.l   $EB8000,a1              ; dst (PCG直接)
        move.l  #1,d0                   ; PCG番号(0～255)dstがramの場合は0を指定する
        jbsr    D012A01_PcgToPcg        ; PCG配列(RAM) → PCG配列(RAM/PCG) DMA転送 (_SP_DEFCG と同等の作用)

        move.l  #0,d0                   ; 反転なし
        move.l  #1,d1                   ; パレットブロック(0～15)
        move.l  #1,d2                   ; PCG番号(0～255)
        bsr     D0123Ax_MkSpPtc         ; パターンコード生成

        move.w  #1,d0                   ; 表示するスプライト番号(0 - 127)
        move.w  #16+128,d1              ; X座標(0-1023)画面左上から-16,-16が起点
        move.w  #16+128,d2              ; Y座標(0-1023)画面左上から-16,-16が起点
                                        ; パターンコードd3.lはそのまま渡す
        move.w  #3,d4                   ; プライオリティ(パラメータの名前と値をequするP.420)
        bsr     D01234A0_PutSp          ; スプライトを表示 (_SP_REGST と同等の作用)

        lea.l   s_title_ini,a6          ; a6:初期シーンの初期化フェーズを設定
        moveq.l #0,d7                   ; ■■■ デバッグ用 ■■■

; アプリケーション メインループ
main_loop:

vsync:                                  ; 60fps 固定
        movea.l #$E88001,a0             ; レジスタアドレス
vsync_1:
        move.b  (a0),d0
        and.b   #$10,d0
        tst.b   d0
        beq     vsync_1
vsync_2:
        move.b  (a0),d0
        and.b   #$10,d0
        tst.b   d0
        bne     vsync_2

        cmp.l   #0,a6                   ; 現在のシーンがNULLなら
        beq     main_release            ; アプリケーション終了処理へ

        jbsr    Input_1P_CreateData     ; 入力情報作成 1P
        jbsr    (a6)                    ; 現在のシーンを実行

        jbra     main_loop              ; 次フレームも継続：メインループ先頭へ

; アプリケーション 終了処理
main_release:

        moveq.l #_SP_INIT,d0            ; PCGをクリアする
        trap    #15

        moveq.l #_G_CLR_ON,d0           ; グラフィック画面をクリア(パレットも標準に戻る)
        trap    #15

                                        ; テキスト画面のクリア
        jbsr    DxA0_SetTxPalDef        ; テキストパレットをデフォルト色に戻す

        moveq.l #_CRTMOD,d0             ; 画面モードを戻す
        move.w  #16,d1                  ; 画面モードの番号
        trap    #15

        move.w  #-1,-(sp)               ; キーバッファのクリア
        DOS     _KFLUSH                 ;
        addq.l  #2,sp                   ; sp戻し

        move.l  ssp_work,-(sp)          ; スーパーバイザモード OFF
        DOS     _SUPER                  ;
        addq.l  #4,sp                   ; sp戻し

        DOS     _EXIT                   : プログラム終了
