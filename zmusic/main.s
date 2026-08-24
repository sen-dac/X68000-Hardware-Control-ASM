;------------------------------------------------------------------------------
; Assemble with HAS060.X
;------------------------------------------------------------------------------
; filename:    main.s
; version:     1. 0. 0
; author:      SEN::DAC
; Description: メイン処理
;------------------------------------------------------------------------------
                .68000
;------------------------------------------------------------------------------
                .include iocscall.mac
                .include doscall.mac
                .include ./se_music/se_music.h

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
        move.w  #18,-(sp)               ; 引数：MOD:18 カーソル表示 OFF
        DOS     _CONCTRL                ; $ff23
        addq.l  #2,sp                   ; sp戻し

        clr.l   -(sp)                   ; 引数：0
        DOS     _SUPER                  ; $ff20 スーパーバイザモード ON
        addq.l  #4,sp                   ; sp戻し
        move.l  d0,ssp_work             ; ssp保存

        move.w  #4,d1                   ; 引数：画面モード番号 : 4 = 512*512*4
        IOCS    _CRTMOD                 ; 画面モードを設定
        jbsr    DxAx_Crt384             ; 特殊画面モードで上書き(384*256)

        IOCS    _G_CLR_ON               ; 画面クリア & 表示ON
        IOCS    _SP_INIT                ; PCGクリア
        IOCS    _SP_ON                  ; スプライト表示 ON

;       ZMUSIC  _ZM_INIT                ; 音源,ドライバの初期化(現状無くても鳴る)

        lea.l   init_pal,a0             ; 引数：登録元データの先頭アドレス   設定値：ALL黒パレット
        lea.l   $E82000,a1              ; 引数：登録先パレットの先頭アドレス 設定値：GRパレット
        jbsr    D012A01_SetPal16        ; パレット登録

        lea.l   init_pal,a0             ; 引数：登録元データの先頭アドレス   設定値：ALL黒パレット
        lea.l   $E82220,a1              ; 引数：登録先パレットの先頭アドレス 設定値：SPパレット
        jbsr    D012A01_SetPal16        ; パレット登録

        lea.l   s_title_ini,a6          ; a6:初期シーンの初期化フェーズを設定

; アプリケーション メインループ
main_loop:
vsync:                                  ; V-SYNC 同期 (60fps に固定される)
        movea.l #$E88001,a0             ; レジスタアドレス
vsync_1:
        move.b  (a0),d0                 ;
        and.b   #$10,d0                 ;
        tst.b   d0                      ;
        beq     vsync_1                 ;
vsync_2:
        move.b  (a0),d0                 ;
        and.b   #$10,d0                 ;
        tst.b   d0                      ;
        bne     vsync_2                 ;

        cmp.l   #0,a6                   ; 現在のシーンがNULLなら
        beq     main_release            ; アプリケーション終了処理へ

        jbsr    Input_1P_CreateData     ; 入力情報作成 1P
;        jbsr    Input_2P_CreateData     ; 入力情報作成 2P

        jbsr    (a6)                    ; 現在のシーンを実行

        jbra     main_loop              ; 次フレームも継続：メインループ先頭へ

; アプリケーション 終了処理
main_release:

        move.l  #85,d2                  ; 引数：d2.l=1(遅)～85(速):フェードアウト
        ZMUSIC  _ZM_FADE                ; 演奏フェードイン/アウト
;       ZMUSIC  _ZM_M_STOP              ; 演奏停止

        IOCS    _SP_INIT                ; PCGクリア
        IOCS    _G_CLR_ON               ; グラフィック画面クリア(パレットも標準に戻る)
                                        ; テキスト画面のクリア
        jbsr    DxA0_SetTxPalDef        ; テキストパレットをデフォルト色に戻す

        move.w  #16,d1                  ; 画面モードの番号
        IOCS    _CRTMOD                 ; 画面モードを戻す

        clr.l   -(sp)                   ; 引数：$00 ($01,$06,$07,$08,$0a 以外の値を指定するとキーバッファのクリアのみを行う)
        DOS     _KFLUSH                 ; $ff0c キーバッファのクリア
        addq.l  #2,sp                   ; sp戻し

        move.l  ssp_work,-(sp)          ; 引数：起動時に保存しておいたssp
        DOS     _SUPER                  ; $ff20 スーパーバイザモード OFF
        addq.l  #4,sp                   ; sp戻し

        move.w  #17,-(sp)               ; 引数：MOD:17 カーソル表示 ON
        DOS     _CONCTRL                ; $ff23
        addq.l  #2,sp                   ; sp戻し

        DOS     _EXIT                   : プログラム終了
