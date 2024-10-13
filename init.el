;;; Personal configuration -*- lexical-binding: t; -*-

(eval-when-compile
  (require 'use-package))

;; Store automatic customization options elsewhere
(setopt custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

(use-package package
  :preface
  (defun make-repourl (repo)
    (format "https://mirrors.tuna.tsinghua.edu.cn/elpa/%s/" repo))
  :custom
  (package-archives `(("gnu" . ,(make-repourl 'gnu))
		      ("nongnu" . ,(make-repourl 'nongnu))
		      ("melpa-stable" . ,(make-repourl 'stable-melpa))
		      ("melpa" . ,(make-repourl 'melpa))))
  (package-archive-priorities '(("gnu" . 99)
				("nongnu" . 90)
				("melpa-stable" . 80)))
  :config
  (package-install-selected-packages)
  (package-vc-install-selected-packages))

(use-package emacs
  :custom
  (window-resize-pixelwise t)
  (frame-resize-pixelwise t)

  ;; Show column numbering in mode lines
  (column-number-mode t)

  (save-place-mode t)
  (savehist-mode t)
  (recentf-mode t)

  (repeat-mode t)
  (delsel-selection-mode t)
  (global-so-long-mode t)
  :custom-face
  (fixed-pitch ((t (:family "Sarasa Fixed SC"))))
  (fixed-pitch-serif ((t (:family "Iosevka Fixed Slab"))))
  (variable-pitch ((t (:family "Sarasa UI SC"))))
  :preface
  (defun get-scaling-size ()
    "Return the scaling size of the first monitor."
    (if (not (equal window-system 'w32))
	1 ; Not supported on platforms other than Win32
      (let* ((lines (process-lines "wmic" "DesktopMonitor" "get" "PixelsPerXLogicalInch"))
	     (dpi (string-to-number (nth 1 lines))))
        (/ dpi 96.0) ; 96 is the default DPI on Windows
	)))
  :init
  (add-to-list 'default-frame-alist '(width . 132))
  (add-to-list 'default-frame-alist '(font . "Sarasa Term SC-10.5"))

  (if (display-graphic-p)
      (set-fringe-mode (round (* 8 (get-scaling-size)))))

  (cond ((version< emacs-version "27") (setopt icomplete-mode t))
	((version< emacs-version "28") (setopt fido-mode t))
	(t
	 (setopt completions-detailed t)
	 (setopt fido-vertical-mode t)))
  :config
  (if (display-graphic-p)
      (load-theme 'leuven t))
  :hook (((prog-mode text-mode) . display-fill-column-indicator-mode)
	 (prog-mode . hl-line-mode)))

(use-package fringe-scale
  :if (display-graphic-p)
  :config
  ;; Scale fringe bitmaps according to the current width
  (fringe-scale-setup))

(use-package display-line-numbers
  ;; Enable line numbering in `prog-mode'
  :hook prog-mode)

(use-package elec-pair
  :custom
  ;; Automatically pair parentheses
  (electric-pair-mode t))

;;;; LSP support
(use-package eglot
  :defer t
  :preface
  (defun eglot-add-to-flymake ()
    (add-hook 'flymake-diagnostic-functions 'eglot-flymake-backend nil t))
  :config
  ;; Keep existing Flymake backends in Eglot-enabled buffers
  (add-to-list 'eglot-stay-out-of 'flymake)
  (add-hook 'eglot-managed-mode-hook #'eglot-add-to-flymake)
  
  ;; Add BasedPyright as Python LSP server
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
		 "basedpyright-langserver" "--stdio")))

;;;; Inline static analysis
(use-package flymake
  :hook prog-mode
  :bind (nil
	 ;; Message navigation bindings
	 :map flymake-mode-map
	 ("M-n" . flymake-goto-next-error)
	 ("M-p" . flymake-goto-prev-error)))

;;;; Indication of local VCS changes
(use-package diff-hl
  :defer t
  :init
  (add-hook 'prog-mode-hook
	    (if (display-graphic-p) #'diff-hl-mode #'diff-hl-margin-mode)))

;;;; C family support
(use-package cc-mode
  :defer t
  :custom
  (c-default-style '((java-mode . "java")
		     (awk-mode . "awk")
		     (other . "stroustrup"))))

;;;; LaTeX support
(use-package auctex
  :defer t
  :init
  (setopt TeX-auto-save t)
  (setopt TeX-parse-self t)
  (setq-default TeX-master nil)
  (setopt TeX-engine 'xetex)
  :hook (LaTeX-mode . LaTeX-math-mode) ; Enable LaTeX math support
  )

(use-package reftex
  :custom
  (reftex-plug-into-AUCTeX t)
  :hook (LaTeX-mode . turn-on-reftex) ; Enable reference management
  )

;;;; EditorConfig support
(use-package editorconfig
  :diminish
  :custom
  ;; Enable EditorConfig
  (editorconfig-mode t))

;;;; Jump to arbitrary positions
(use-package avy
  :bind ("M-g w" . avy-goto-word-1))

;;;; Display available key bindings in popup
(use-package which-key
  :diminish
  :config
  (which-key-mode)
  )

;;;; The Emacs guru way
(use-package guru-mode
  :diminish guru-mode
  :hook prog-mode)

;;;; Undo and redo window changes
(use-package winner
  :custom
  (winner-mode t)
  ;; Restore window layout after closing ediff
  :hook (ediff-quit . winner-undo))

(use-package face-remap
  ;; Use variable pitch fonts in Info reader
  :hook (Info-mode . variable-pitch-mode))
