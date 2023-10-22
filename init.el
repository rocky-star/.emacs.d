;;; Personal configuration  -*- lexical-binding: t; -*-

(use-package emacs
  :custom
  (window-resize-pixelwise t)
  (frame-resize-pixelwise t)

  ;; Enable recursive minibuffers
  (enable-recursive-minibuffers t)
  :config
  ;; Do not allow the cursor in the minibuffer prompt
  (setopt minibuffer-prompt-properties
	  '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode))

(use-package simple
  :custom
  ;; Hide commands in M-x which do not work in the current mode.
  ;; Vertico commands are hidden in normal buffers.
  (read-extended-command-predicate #'command-completion-default-include-p))

(use-package files
  :custom
  (backup-directory-alist `(("." . ,temporary-file-directory))))

(use-package package
  :defer t
  :custom
  (package-archives '(("gnu" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
		      ("nongnu" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/")
		      ("melpa-stable" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/stable-melpa/")
		      ("melpa" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))
  (package-archive-priorities '(("gnu" . 99)
				("nongnu" . 90)
				("melpa-stable" . 80)
				("melpa" . 70))))

(use-package crm
  :preface
  (defun my/crm-indicator (args)
    (cons (format "[CRM%s] %s"
		  (replace-regexp-in-string
		   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
		   crm-separator)
		  (car args))
	  (cdr args)))
  :config
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (advice-add #'completing-read-multiple :filter-args #'my/crm-indicator))

(use-package fringe
  :if window-system
  :preface
  (defun my/get-scaling-factor ()
    "Return the current scaling factor on Windows."
    (let* ((full-out (shell-command-to-string "WMIC DESKTOPMONITOR GET PixelsPerXLogicalInch"))
	   (line-out (nth 1 (split-string full-out))))
      ;; 96 is the standard DPI on Windows and Linux.
      (/ (string-to-number line-out) 96.0)))
  :custom
  ;; As per the documentation, the default width of the fringe is 8 pixels.
  (fringe-mode (round (* 8 (my/get-scaling-factor)))))

(use-package color-theme-sanityinc-tomorrow
  :if window-system
  :config
  (load-theme 'sanityinc-tomorrow-day t))

(defvar *my/current-theme* 'light "Current theme.  dark or light.")
(defun my/toggle-color ()
  "Toggle the color theme between light & dark themes."
  (interactive)
  (if (equal *my/current-theme* 'light)
      (progn (load-theme 'sanityinc-tomorrow-night t)
	     (setq *my/current-theme* 'dark))
    (progn (load-theme 'sanityinc-tomorrow-day t)
	   (setq *my/current-theme* 'light))))

(use-package faces
  :if window-system
  :custom-face
  (default ((t (:font "Maple Mono NF"))))
  (variable-pitch ((t (:font "Calibri"))))
  (fixed-pitch ((t (:font "Courier Prime"))))
  (fixed-pitch-sans-serif ((t (:font "Courier Prime Sans"))))
  :config
  (dolist (charset '(kana han cjk-misc bopomofo))
    (set-fontset-font "fontset-default" charset "Maple Mono SC NF")))

;;; Completion framework
(use-package vertico
  :demand
  :config
  (vertico-mode)
  :bind (;; Bind default completion commands in the Vertico keymap
	 :map vertico-map
	      ("?" . minibuffer-completion-help)
	      ("M-RET" . minibuffer-force-complete-and-exit)
	      ("M-TAB" . minibuffer-complete)))

(use-package vertico-directory
  :after vertico
  :bind (;; More convenient directory navigation commands
	 :map vertico-map
	      ("RET" . vertico-directory-enter)
	      ("DEL" . vertico-directory-delete-char)
	      ("M-DEL" . vertico-directory-delete-word))
  ;; Tidy shadowed file names
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package orderless
  :custom
  (completion-styles '(substring orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;;; Extended completion utilties
(use-package consult
  ;; Replace bindings. Lazily loaded due by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
	 ;; ("C-c M-x" . consult-mode-command)
	 ;; ("C-c h" . consult-history)
	 ;; ("C-c k" . consult-kmacro)
	 ;; ("C-c m" . consult-man)
	 ;; ("C-c i" . consult-info)
	 ([remap Info-search] . consult-info)
	 ;; C-x bindings in `ctl-x-map'
	 ("C-x M-:" . consult-complex-command) ;; orig. repeat-complex-command
	 ("C-x b" . consult-buffer) ;; orig. switch-to-buffer
	 ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
	 ("C-x 5 b" . consult-buffer-other-frame) ;; orig. switch-to-buffer-other-frame
	 ("C-x r b" . consult-bookmark) ;; orig. bookmark-jump
	 ("C-x p b" . consult-project-buffer) ;; orig. project-switch-to-buffer
	 ;; Custom M-# bindings for fast register access
	 ;; ("M-#" . consult-register-load)
	 ;; ("M-'" . consult-register-store) ;; orig. abbrev-prefix-mark (unrelated)
	 ;; ("C-M-#" . consult-register)
	 ;; Other custom bindings
	 ("M-y" . consult-yank-pop) ;; orig. yank-pop
	 ;; M-g bindings in `goto-map'
	 ("M-g e" . consult-compile-error)
	 ("M-g f" . consult-flymake) ;; Alternative: consult-flycheck
	 ("M-g g" . consult-goto-line) ;; orig. goto-line
	 ("M-g M-g" . consult-goto-line) ;; orig. goto-line
	 ("M-g o" . consult-outline) ;; Alternative: consult-org-heading
	 ;; ("M-g m" . consult-mark)
	 ;; ("M-g k" . consult-global-mark)
	 ("M-g i" . consult-imenu)
	 ("M-g I" . consult-imenu-multi)
	 ;; M-s bindings in `search-map'
	 ;; ("M-s d" . consult-find)
	 ;; ("M-s D" . consult-locate)
	 ;; ("M-s g" . consult-grep)
	 ;; ("M-s G" . consult-git-grep)
	 ("M-s r" . consult-ripgrep)
	 ("M-s l" . consult-line)
	 ("M-s L" . consult-line-multi)
	 ;; ("M-s k" . consult-keep-lines)
	 ;; ("M-s u" . consult-focus-lines)
	 ;; Isearch integration
	 ("M-s e" . consult-isearch-history)
	 :map isearch-mode-map
	 ("M-e" . consult-isearch-history) ;; orig. isearch-edit-string
	 ("M-s e" . consult-isearch-history) ;; orig. isearch-edit-string
	 ("M-s l" . consult-line) ;; needed by consult-line to detect isearch
	 ("M-s L" . consult-line-multi) ;; needed by consult-line to detect isearch
	 ;; Minibuffer history
	 :map minibuffer-local-map
	 ("M-s" . consult-history) ;; orig. next-matching-history-element
	 ("M-r" . consult-history)) ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setopt register-preview-delay 0.5
	  register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setopt xref-show-xrefs-function #'consult-xref
	  xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setopt consult-narrow-key "<"))

(use-package display-line-numbers
  ;; Enable line numbering in `prog-mode'
  :hook prog-mode)

(use-package elec-pair
  ;; Automatically pair parentheses
  :hook ((prog-mode text-mode) . electric-pair-mode))

;;; Inline static analysis
(use-package flymake
  :bind (;; Message navigation bindings
	 :map flymake-mode-map
	      ("M-n" . flymake-goto-next-error)
	      ("M-p" . flymake-goto-prev-error))
  ;; Enable inline static analysis
  :hook prog-mode)

;;; Pop-up completion
(use-package corfu
  :demand
  ;; Optional customizations
  :custom
  ;; (corfu-cycle t) ;; Enable cycling for `corfu-next/previous'
  ;; (corfu-auto t) ;; Enable auto completion
  (corfu-separator ?\s) ;; Orderless field separator
  ;; (corfu-quit-at-boundary nil) ;; Never quit at completion boundary
  ;; (corfu-quit-no-match nil) ;; Never quit, even if there is no match
  ;; (corfu-preview-current nil) ;; Disable current candidate preview
  ;; (corfu-preselect 'prompt) ;; Preselect the prompt
  ;; (corfu-on-exact-match nil) ;; Configure handling of exact matches
  ;; (corfu-scroll-margin 5) ;; Use scroll margin

  :bind (;; Configure SPC for separator insertion.
	 :map corfu-map
	      ("SPC" . corfu-insert-separator))

  ;; Enable Corfu globally.
  :config
  (global-corfu-mode))

;;; Git client
(use-package magit
  :defer t
  :custom
  (magit-refresh-status-buffer nil))

;;; Indication of local VCS changes
(use-package diff-hl
  :after magit
  ;; Enable `diff-hl' support by default in programming buffers
  :hook ((prog-mode .turn-on-diff-hl-mode)
	 (magit-pre-refresh . diff-hl-magit-pre-refresh)
	 (magit-post-refresh . diff-hl-magit-post-refresh)))

;; C family support
(use-package cc-mode
  :defer t
  :custom
  (c-default-style '((java-mode . "java")
		     (awk-mode . "awk")
		     (other . "stroustrup"))))

;;; LaTeX support
(use-package auctex
  :defer t
  :custom
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-master nil)
  (japanese-TeX-engine-default 'uptex))

;;; EditorConfig support
(use-package editorconfig
  :delight
  :config
  (editorconfig-mode))

;;; Key suggestions
(use-package which-key
  :delight
  :config
  (which-key-mode))

;;; Smart Chinese input method
(use-package pyim
  :defer t
  :custom
  (default-input-method "pyim"))

(use-package pyim-basedict
  :after pyim
  :config
  (pyim-basedict-enable))

(use-package pyim-tsinghua-dict
  :after pyim
  :config
  (pyim-tsinghua-dict-enable))

;;; Configuration profiler
(use-package esup
  :defer t
  :custom
  (esup-depth 0))

;;; Miscellaneous options
(use-package saveplace
  :config
  (save-place-mode))

(use-package savehist
  :config
  (savehist-mode))

(use-package recentf
  :config
  (recentf-mode))

;; Store automatic customization options elsewhere
(setopt custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))
