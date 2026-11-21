;
; workdisk.inc
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The workdisk overlay (src/overlays/workdisk, plans/workdisks.md): it
; checks, makes and refreshes a work disk.
;
; Each routine returns a WD_* code in A, with the Z flag set for WD_OK.
; They open their own files and command channels (logical files 2, 3, 14
; and 15) and close them before they return.

WORKDISK_BASE = $4000

; The overlay defines WORKDISK_OVERLAY, since these are its own procs
.ifndef WORKDISK_OVERLAY
wdCheck = WORKDISK_BASE + 0     ; A: unit. WD_OK if it is a work disk
wdCreate = WORKDISK_BASE + 3    ; A: unit. Makes a blank disk a work disk
wdRefresh = WORKDISK_BASE + 6   ; Copies runtimeN to workDevice if missing
wdDialog = WORKDISK_BASE + 9    ; The startup dialog: sets workDevice
wdStartup = WORKDISK_BASE + 12  ; Finds the work disk, or shows the dialog
wdUse = WORKDISK_BASE + 15      ; A: unit. Check, refresh, print an error

; Only in the test build of the overlay (make WORKDISKTEST=1). See
; wdtest.s in the overlay.
wdTestSetup = WORKDISK_BASE + 18    ; A/X: the key script
wdTestRun = WORKDISK_BASE + 21      ; A 0: wdDialog, else wdStartup
wdTestState = WORKDISK_BASE + 24    ; A/X: the dialog's log (wdtest.s)
.endif

; The units wdStartup looks for a work disk on
WD_FIRST_PROBE = 9
WD_LAST_PROBE = 11

; The unit the startup dialog offers first
WD_DEFAULT_UNIT = 9
WD_FIRST_UNIT = 8
WD_LAST_UNIT = 30

; The codes
WD_OK = 0           ; A work disk (wdCheck), or done
WD_BLANK = 1        ; wdCheck: no files on the disk
WD_NOTBLANK = 2     ; wdCheck: files and no marker; wdCreate: any files
WD_BADMARKER = 3    ; The marker isn't one this release reads
WD_NODEVICE = 4     ; Nothing answers on the unit
WD_NOTREADY = 5     ; No disk in the drive (DOS 74)
WD_SYSDISK = 6      ; The unit is the system disk's
WD_IOERROR = 7      ; A read or write failed (the disk full, protected)
WD_NORUNTIME = 8    ; runtimeN isn't on the system disk
WD_BADUNIT = 9      ; wdDialog, wdUse: a unit given isn't 8 to 30

; The marker, p65work (SEQ):
;    WD_MAGIC0, WD_MAGIC1, WD_VERSION
;    the release that made it, PETSCII, zero-terminated
; A marker of a later version is read as far as this one goes, so
; settings can be added after the release.
.define WD_MARKER "p65work"
WD_MAGIC0 = 'P'
WD_MAGIC1 = 'W'
WD_VERSION = 1
; The release being made, the first line of ChangeLog.txt
.define WD_RELEASE "0.38-beta"
