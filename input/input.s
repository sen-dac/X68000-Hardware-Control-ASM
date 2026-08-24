;------------------------------------------------------------------------------
; Assemble with HAS060.X
;------------------------------------------------------------------------------
; filename:    input.s
; version:     1. 0. 0
; author:      SEN::DAC
; Description: 入力処理
;------------------------------------------------------------------------------
                .include doscall.mac    ; _KFLUSH キーバッファをクリア
                .include iocscall.mac   ; _BITSNS
                .include ./input/input.h

; -----------------------------------------------------------------------------
                .bss
                .even
; -----------------------------------------------------------------------------
; コントローラー情報
; -----------------------------------------------------------------------------
Controller1:    ; コントローラ1
C1_Dat:         .ds.w   1               ; ボタンの状態
C1_Pre:         .ds.w   1               ; 前回の状態
C1_Chg:         .ds.w   1               ; 変更

C1_Dow:         .ds.w   1               ; 押した瞬間
C1_Pus:         .ds.w   1               ; 押し続け
C1_Up_:         .ds.w   1               ; 離した瞬間
C1_Rel:         .ds.w   1               ; 離し続け

Controller2:    ; コントローラ2
C2_Dat:         .ds.w   1               ; ボタンの状態
C2_Pre:         .ds.w   1               ; 前回の状態
C2_Chg:         .ds.w   1               ; 変更

C2_Dow:         .ds.w   1               ; 押した瞬間
C2_Pus:         .ds.w   1               ; 押し続け
C2_Up_:         .ds.w   1               ; 離した瞬間
C2_Rel:         .ds.w   1               ; 離し続け

; -----------------------------------------------------------------------------
                .text
                .even
; -----------------------------------------------------------------------------
; コントローラ情報のディスプレースメント d(ax)
; -----------------------------------------------------------------------------
D_Dat           equ     0               ; ボタンの状態
D_Pre           equ     2               ; 前回の状態
D_Chg           equ     4               ; 変更
D_Dow           equ     6               ; 押した瞬間
D_Pus           equ     8               ; 押し続け
D_Up_           equ     10              ; 離した瞬間
D_Rel           equ     12              ; 離し続け

; -----------------------------------------------------------------------------
; ジョイスティックの押下状態を取得する
; a0.lに対象ジョイスティックレジスタのアドレスを格納してから呼び出す
; btn = レジスタ側ビット, bit = ram側ビット, dat = ram, (label = 成立時のジャンプ先)
; -----------------------------------------------------------------------------
JoySnsE .macro btn,bit,dat,label

        move.w  (a0),d0                 ; ジョイスティックレジスタの値をd0.wに取得(対象bit 1:OFF / 0:ON)
        andi.w  #btn,d0                 ; 演算結果が0なら押されている
        bne     @end                    ; 0でないなら押されていないので最後にジャンプ(何もしない)
        ori.w   #bit,dat                ; 押されている場合は対象ビットを立てる
        bra     label                   ; 押されている場合は無条件ジャンプ
@end:
                .endm

JoySns .macro btn,bit,dat
        move.w  (a0),d0                 ; ジョイスティックレジスタの値をd0.wに取得(対象bit 1:OFF / 0:ON)
        andi.w  #btn,d0                 ; 演算結果が0なら押されている
        bne     @end                    ; 0でないなら押されていないので最後にジャンプ(何もしない)
        ori.w   #bit,dat                ; 押されている場合は対象ビットを立てる
@end:
                .endm

; -----------------------------------------------------------------------------
; ジョイスティック(1P)の入力情報を作成する
; パラメータなし
; -----------------------------------------------------------------------------
Input_1P_CreateJoystickData .macro

        lea.l   P8255_PORT_A,a0         ; ジョイスティックレジスタ(1P)のアドレスをロード

        JoySnsE $0003,BTN_SEL,C1_Dat,@f ; セレクトボタン (上下同時押し)
        JoySns  $0001,BTN_UP_,C1_Dat    ; 上ボタン (セレクトボタン else)
        JoySns  $0002,BTN_DOW,C1_Dat    ; 下ボタン (セレクトボタン else)
@@:
        JoySnsE $000C,BTN_STA,C1_Dat,@f ; スタートボタン (左右同時押し)
        JoySns  $0004,BTN_LEF,C1_Dat    ; 左ボタン (スタートボタン else)
        JoySns  $0008,BTN_RIG,C1_Dat    ; 右ボタン (スタートボタン else)
@@:
        JoySns  $0020,BTN_A__,C1_Dat    ; Aボタン
        JoySns  $0040,BTN_B__,C1_Dat    ; Bボタン

                .endm

; -----------------------------------------------------------------------------
; ジョイスティック(2P)の入力情報を作成する
; パラメータなし
; -----------------------------------------------------------------------------
Input_2P_CreateJoystickData .macro

        lea.l   P8255_PORT_B,a0         ; ジョイスティックレジスタ(2P)のアドレスをロード

        JoySnsE $0003,BTN_SEL,C2_Dat,@f ; セレクトボタン (上下同時押し)
        JoySns  $0001,BTN_UP_,C2_Dat    ; 上ボタン (セレクトボタン else)
        JoySns  $0002,BTN_DOW,C2_Dat    ; 下ボタン (セレクトボタン else)
@@:
        JoySnsE $000C,BTN_STA,C2_Dat,@f ; スタートボタン (左右同時押し)
        JoySns  $0004,BTN_LEF,C2_Dat    ; 左ボタン (スタートボタン else)
        JoySns  $0008,BTN_RIG,C2_Dat    ; 右ボタン (スタートボタン else)
@@:
        JoySns  $0020,BTN_A__,C2_Dat    ; Aボタン
        JoySns  $0040,BTN_B__,C2_Dat    ; Bボタン

        .endm

; -----------------------------------------------------------------------------
; キーの押下状態を取得する(1Pのみ)
; kg = キーグループ, kc = キーコード, dat = 書き込み対象RAM
; -----------------------------------------------------------------------------
KeySns          .macro kg,kc,btn,dat

        moveq.l #kg,d1                  ; d1.w = 引数：キーコード・グループナンバー
        IOCS    _BITSNS                 ; キー押下状態の取得(毎取得する方針とした)
                                        ; d0.b = 戻値：押しているとき対応するビットが1になる
        andi.b  #kc,d0                  ; 押されている(T) / 押されていない(F)
        beq     @end                    ; 押されていない(F)場合はローカルラベル@endへ飛ぶ
        ori.w   #btn,dat                ; 押されている(T)場合はRAMの対象ビットを立てる
@end:
                .endm

; -----------------------------------------------------------------------------
; キーボードの入力情報を作成(1Pのみ)
; -----------------------------------------------------------------------------
Input_1P_CreateKeyboardData .macro

        move.w  #-1,-(sp)
        DOS     _KFLUSH                         ; キーバッファをクリア
        addq.l  #2,sp

        KeySns  KG_7,KG_7_UP_,BTN_UP_,C1_Dat    ; 上キー
        KeySns  KG_7,KG_7_DOW,BTN_DOW,C1_Dat    ; 下キー
        KeySns  KG_7,KG_7_LEF,BTN_LEF,C1_Dat    ; 左キー
        KeySns  KG_7,KG_7_RIG,BTN_RIG,C1_Dat    ; 右キー

        KeySns  KG_5,KG_5_X__,BTN_A__,C1_Dat    ; Xキー(Aボタン)
        KeySns  KG_5,KG_5_Z__,BTN_B__,C1_Dat    ; Zキー(Bボタン)

        KeySns  KG_6,KG_6_SP_,BTN_STA,C1_Dat    ; スペースキー(STARTボタン)
        KeySns  KG_3,KG_3_ENT,BTN_SEL,C1_Dat    ; リターンキー(SELECTボタン)

                .endm

; -----------------------------------------------------------------------------
; 入力情報の生成 (共通処理)
; -----------------------------------------------------------------------------
Input_CreateCommon .macro

        ; 変更があった情報を求める      ; Change = Data ^ Prev
        move.w  D_Dat(a0),d0            ; Dat → d0.w
        move.w  D_Pre(a0),d1            ; Pre → d1.w

        eor.w   d1,d0                   ; Dat ^ Pre → d0.w
        move.w  d0,D_Chg(a0)            ; d0.w → Chg

        ; 押した瞬間の情報を求める      ; Down = Data & Change
        move.w  D_Dat(a0),d0            ; Dat → d0.w
        move.w  D_Chg(a0),d1            ; Chg → d1.w
        and.w   d1,d0                   ; Dat & Chg → d0.w
        move.w  d0,D_Dow(a0)            ; d0.w → Dow

        ; 押し続けている情報を求める    ; Press = Data & Prev
        move.w  D_Dat(a0),d0            ; Dat → d0.w
        move.w  D_Pre(a0),d1            ; Pre → d1.w
        and.w   d1,d0                   ; Dat & Pre → d0.w
        move.w  d0,D_Pus(a0)            ; d0.w → Pus

        ; 離した瞬間の情報を求める      ; Up = Change & Prev
        move.w  D_Chg(a0),d0            ; Chg → d0.w
        move.w  D_Pre(a0),d1            ; Pre → d1.w
        and.w   d1,d0                   ; Chg & Pre → d0.w
        move.w  d0,D_Up_(a0)            ; d0.w → Up_

        ; 離している情報を求める        ; Release = ~(Controller[i].Down | Controller[i].Press | Controller[i].Up )
        move.w  D_Dow(a0),d0            ; Dow → d0.w
        move.w  C1_Pus,d1               ; Pus → d1.w
        move.w  C1_Up_,d2               ; Up_ → d2.w
        or.w    d0,d1                   ;
        or.w    d1,d2                   ; Dow | Pus | Up_ → d2.w

        ; 通常ボタン
        bchg.l  #00,d2                  ; ビット00を反転
        bchg.l  #01,d2                  ; ビット01を反転
        bchg.l  #02,d2                  ; ビット02を反転
        bchg.l  #03,d2                  ; ビット03を反転
        bchg.l  #04,d2                  ; ビット04を反転
        bchg.l  #05,d2                  ; ビット05を反転
        bchg.l  #06,d2                  ; ビット06を反転
        bchg.l  #07,d2                  ; ビット07を反転

        ; キーボード(1P)のみの拡張ボタン
        bchg.l  #08,d2                  ; ビット08を反転
        bchg.l  #09,d2                  ; ビット09を反転
        bchg.l  #10,d2                  ; ビット10を反転
        bchg.l  #11,d2                  ; ビット11を反転
        bchg.l  #12,d2                  ; ビット12を反転
        bchg.l  #13,d2                  ; ビット13を反転
        bchg.l  #14,d2                  ; ビット14を反転
        bchg.l  #15,d2                  ; ビット15を反転

        move.w  d2,D_Rel(a0)            ; ~(Dow | Pus | Up_) → Rel

        ; 今回の情報を"次回から見て前回"として保存する
        move.w  D_Dat(a0),D_Pre(a0)     ; Dat → Pre

                .endm

; -----------------------------------------------------------------------------
; 入力情報を作成する
; -----------------------------------------------------------------------------
; コントローラ 1P
Input_1P_CreateData::

        move.w  #0,C1_Dat               ; 入力情報の初期化
        Input_1P_CreateJoystickData     ; ジョイスティックの入力情報を取得
        Input_1P_CreateKeyboardData     ; キーボードの入力情報を取得 (1Pのみ)

        ; 入力情報を生成
        lea.l   Controller1,a0          ; 対象コントローラ → a0
        Input_CreateCommon              ; 入力情報の生成(共通)

        rts

; コントローラ 2P
Input_2P_CreateData::

        move.w  #0,C2_Dat               ; 入力情報の初期化
        Input_2P_CreateJoystickData     ; ジョイスティックの入力情報を取得

        ; 入力情報を生成
        lea.l   Controller2,a0          ; 対象コントローラ → a0
        Input_CreateCommon              ; 入力情報の生成(共通)

        rts

; -----------------------------------------------------------------------------
; コントローラの入力情報を取得する (共通処理)
; -----------------------------------------------------------------------------
Input_GetState .macro

        move.w  d1,d2                   ; ステート(引数)をコピー
        cmp.w   #BS_DOW,d2              ; ステート(引数)は "押した瞬間" か？
        beq     @down                   ; そうなら "押した瞬間" の処理へ飛ぶ

        move.w  d1,d2                   ; ステート(引数)をコピー
        cmp.w   #BS_PUS,d2              ; ステート(引数)は "押し続け" か？
        beq     @press                  ; そうなら "押し続け" の処理へ飛ぶ

        move.w  d1,d2                   ; ステート(引数)をコピー
        cmp.w   #BS_UP_,d2              ; ステート(引数)は "離した瞬間" か？
        beq     @up                     ; そうなら "離した瞬間" の処理へ飛ぶ

        move.w  d1,d2                   ; ステート(引数)をコピー
        cmp.w   #BS_REL,d2              ; ステート(引数)は "離し続け" か？
        beq     @release                ; そうなら "離し続け" の処理へ飛ぶ

        move.w  #0,d0                   ; どれにも該当しない場合、引数が不正である
        bra     @end                    ; 戻り値0で終了

@down:
        and.w   D_Dow(a0),d0            ; 押した瞬間
        bra     @end
@press:
        and.w   D_Pus(a0),d0            ; 押し続け
        bra     @end
@up:
        and.w   D_Up_(a0),d0            ; 離した瞬間
        bra     @end
@release:
        and.w   D_Rel(a0),d0            ; 離し続け
@end:
                .endm

; -----------------------------------------------------------------------------
; コントローラの入力情報を取得する
;
; - IN  : d0.w btn
;         d1.w state
; - OUT : d0.w T:指定したボタンが指定した状態である / F:指定したボタンが指定した状態ではない
; -----------------------------------------------------------------------------
; コントローラ 1P
Input_1P_GetState::

        lea.l   Controller1,a0          ; コントローラ(1P)情報のアドレス → a0
        Input_GetState                  ; コントローラの入力情報を取得する

        rts

; コントローラ 2P
Input_2P_GetState::

        lea.l   Controller2,a0          ; コントローラ(2P)情報のアドレス → a0
        Input_GetState                  ; コントローラの入力情報を取得する

        rts

; -----------------------------------------------------------------------------
; コントローラの入力情報を格納するRAMの先頭アドレスを返す (デバッグ用)
;
; - IN  : なし
; - OUT : a0.l コントローラの入力情報を格納するRAMの先頭アドレス
; -----------------------------------------------------------------------------
; コントローラ 1P
Input_1P_GetRamAddr::

        lea.l   Controller1,a0          ;

        rts

; コントローラ 2P
Input_2P_GetRamAddr::

        lea.l   Controller2,a0          ;

        rts

