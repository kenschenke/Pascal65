;
; pkgbss.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Variables for the runtime packages (see rtpkg.inc)
;
; Packages follow the core, and each is linked at more than one address. Its
; variables must have the same address in every variant, so they're reserved
; here, at the end of the core, whether or not the package is linked.

.include "rtpkg.inc"

.export dynArrayBss, fileOpsBss

.segment "PKGBSS"

dynArrayBss: .res DYNARRAYS_BSS_SIZE    ; dynarray.s
fileOpsBss: .res FILES_BSS_SIZE         ; fileops.s
