;; (C) 2009 Rémi Vanicat <vanicat@debian.org>

;; xmms2.el is a music player for Emacs that uses xmms2 as its backend

;;     This program is free software; you can redistribute it and/or
;;     modify it under the terms of the GNU General Public License as
;;     published by the Free Software Foundation; either version 3 of
;;     the License, or (at your option) any later version.

;;     This program is distributed in the hope that it will be useful,
;;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;;     GNU General Public License for more details.

;;     You should have received a copy of the GNU General Public
;;     License along with this program; if not, write to the Free
;;     Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;;     Boston, MA 02110-1301 USA

(defvar xmms2-playlist nil
  "The xmms2 playlist, an list of (ID ARTIST ALBUM TITLE) for the current playlist")

(defvar xmms2-now-playing nil
  "The song that is being played now")

(defgroup xmms2 ()
  "xmms2.el is a client for xmms2 written in emacs lisp")

(defcustom xmms2-command
  "nyxmms2"
  "The command to run for xmms2 command. Must be API compatible with nyxmms2"
  :group 'xmms2
  :type 'string)

(defvar xmms2-process ())
(defvar xmms2-callback-queue ()
  "queue of callback to be run from the filter")

(defun xmms2-process-filter (proc str)
  (with-current-buffer (process-buffer xmms2-process)
    (goto-char (process-mark xmms2-process))
    (insert str)
    (set-marker (process-mark proc) (point))
    (goto-char (point-min))
    (while (search-forward-regexp "xmms2> *$" () t)
      (let ((response (buffer-substring (point-min) (match-beginning 0))))
	(delete-region (point-min) (match-end 0))
	(apply (pop xmms2-callback-queue) (list response))))))

(defun xmms2-callback-message (response)
  (message response))

(defun xmms2-init-process ()		;TODO: add option for server and such
  (setq xmms2-process (start-process "nyxmms2" " *nyxmms2*" xmms2-command))
  (setq xmms2-callback-queue (append xmms2-callback-queue (list 'xmms2-callback-message)))
  (set-process-filter xmms2-process 'xmms2-process-filter))

(defun xmms2-call (callback command &rest args)
  (let ((string (format command args)))
    (process-send-string xmms2-process string)
    (process-send-string xmms2-process "\n")
    (setq xmms2-callback-queue (append xmms2-callback-queue (list callback)))))

(defun xmms2-callback-status (response)
  (setq xmms2-now-playing response)
  (message response))

(defun xmms2-status ()
  (interactive)
  (xmms2-call 'xmms2-callback-status "status"))

(defun xmms2-callback-list (response)
  (setq xmms2-playlist response)
  (message response))

(defun xmms2-list ()
  (interactive)
  (xmms2-call 'xmms2-callback-list "list"))
