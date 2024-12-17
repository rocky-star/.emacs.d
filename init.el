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

  ;; Hide commands in M-x which do not apply to the current mode
  (read-extended-command-predicate #'command-completion-default-include-p)
  :custom-face
  (variable-pitch ((t (:family "IBM Plex Sans"))))
  :preface
  (defun get-scaling-size ()
    "Return the scaling size of the first monitor."
    (if (not (equal window-system 'w32))
	1 ; Not supported on platforms other than Win32
      (let* ((lines (process-lines "wmic" "DesktopMonitor" "get" "PixelsPerXLogicalInch"))
	     (dpi (string-to-number (nth 1 lines))))
        (/ dpi 96.0) ; 96 is the default DPI on Windows
	)))

  (defun enable-dark-theme ()
    (interactive)
    (disable-theme 'leuven)
    (load-theme 'leuven-dark t))

  (defun enable-light-theme ()
    (interactive)
    (disable-theme 'leuven-dark)
    (load-theme 'leuven t))
  :init
  (add-to-list 'default-frame-alist '(font . "IBM Plex Mono-10.5"))

  (if (display-graphic-p)
      (set-fringe-mode (round (* 8 (get-scaling-size)))))

  (cond ((version< emacs-version "27") (setopt icomplete-mode t))
	((version< emacs-version "28") (setopt fido-mode t))
	(t
	 (setopt completions-detailed t)
	 (setopt fido-vertical-mode t)))

  (setq treesit-language-source-alist
	'((bash "https://github.com/tree-sitter/tree-sitter-bash")
	  (cmake "https://github.com/uyha/tree-sitter-cmake")
	  (css "https://github.com/tree-sitter/tree-sitter-css")
	  (elisp "https://github.com/Wilfred/tree-sitter-elisp")
	  (go "https://github.com/tree-sitter/tree-sitter-go")
	  (html "https://github.com/tree-sitter/tree-sitter-html")
	  (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
	  (json "https://github.com/tree-sitter/tree-sitter-json")
	  (make "https://github.com/alemuller/tree-sitter-make")
	  (markdown "https://github.com/ikatyang/tree-sitter-markdown")
	  (python "https://github.com/tree-sitter/tree-sitter-python")
	  (toml "https://github.com/tree-sitter/tree-sitter-toml")
	  (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
	  (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
	  (yaml "https://github.com/ikatyang/tree-sitter-yaml")))
  :config
  (if (>= (display-color-cells) 256)
      (load-theme 'leuven t))
  (if (not (display-graphic-p))
      (xterm-mouse-mode))
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

(use-package eglot-booster
  :config
  (eglot-booster-mode))

;;;; Inline static analysis
(use-package flymake
  :hook prog-mode
  :bind (nil
	 ;; Message navigation bindings
	 :map flymake-mode-map
	 ("M-n" . flymake-goto-next-error)
	 ("M-p" . flymake-goto-prev-error)))

;;;; Pop-up completion
(use-package corfu
  :custom
  (corfu-auto t)
  :config
  (global-corfu-mode))

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

;;;; Enhanced Pinyin input method
(use-package pyim
  :defer t
  :custom
  (default-input-method "pyim"))

(use-package pyim-basedict
  :after pyim
  :config
  (pyim-basedict-enable))

(use-package pyim-tsinghua-dict
  :after (pyim pyim-basedict)
  :config
  (pyim-tsinghua-dict-enable))

(use-package pyim-cregexp-utils
  :after pyim
  :diminish pyim-isearch-mode
  :config
  (pyim-isearch-mode 1))

(use-package pyim-cstring-utils
  :after pyim
  :bind (([remap forward-word] . pyim-forward-word)
	 ([remap backward-word] . pyim-backward-word)))

(use-package face-remap
  ;; Use variable pitch fonts in Info reader
  :hook (Info-mode . variable-pitch-mode))
