;;; init.el --- Emacs configuration -*- lexical-binding: t -*-

;;; Commentary:
;; A clean, vanilla Emacs configuration.
;; Uses Elpaca for package management.

;;; Code:


;;; -- Elpaca bootstrap --

(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package integration with Elpaca.
(elpaca elpaca-use-package
  ;; Enable :ensure support for Elpaca in use-package.
  (elpaca-use-package-mode)
  ;; Make :ensure t the default.
  (setq use-package-always-ensure t))


;;; -- Need newer versions --
(use-package compat)
(use-package transient)


;;; -- Helper functions --

(defun mzacuna/apply-theme (theme)
  "Disable active themes and load THEME (a symbol).
When called interactively, prompt for THEME with completion.
Vanilla `load-theme' stacks themes on top of each other, which produces
visual artifacts; this helper disables active themes first."
  (interactive
   (list (intern (completing-read "Apply custom theme: "
                                  (mapcar #'symbol-name
                                          (custom-available-themes))))))
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme t))


;;; -- Housekeeping --

;; Keep ~/.config/emacs clean by redirecting state and cache files.
;; Must be configured before other packages write their files.
(use-package no-littering
  :demand t
  :config
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))


;;; -- Core defaults --

(use-package emacs
  :ensure nil
  :init
  ;; Bumping these meaningfully improves LSP responsiveness.
  ;; LSP servers send large JSON payloads; the default 4 KiB read buffer
  ;; causes many syscalls. 4 MiB is the lsp-mode performance recommendation.
  (setq read-process-output-max (* 4 1024 1024))
  ;; gc-cons-threshold is restored from `most-positive-fixnum' (set in
  ;; early-init.el) to a saner value here. lsp-mode performance docs
  ;; recommend 100 MiB or higher for LSP work.
  (setq gc-cons-threshold (* 100 1024 1024))

  :custom
  ;; TAB does indent-or-complete based on context. Required for Corfu.
  (tab-always-indent 'complete)
  ;; Disable Emacs 30's ispell-based text-mode completion, which
  ;; interferes with Corfu in text buffers.
  (text-mode-ispell-word-completion nil)
  ;; Hide commands in M-x that don't apply to the current mode.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Allow opening minibuffers from inside other minibuffers.
  (enable-recursive-minibuffers t)
  ;; Don't let the cursor enter the minibuffer prompt.
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))

  :config
  ;; Encoding
  (set-language-environment "UTF-8")

  ;; General
  (setq load-prefer-newer t
        use-short-answers t
        make-backup-files nil
        sentence-end-double-space nil
        inhibit-startup-screen t
        initial-scratch-message nil
        initial-major-mode 'fundamental-mode
        ring-bell-function #'ignore)

  ;; Scrolling
  ;; (setq scroll-conservatively 101
  ;;       scroll-margin 3)
  ;; (pixel-scroll-precision-mode 1)

  ;; Visuals
  (setq-default truncate-lines t
                indent-tabs-mode nil
                tab-width 4)
  (column-number-mode 1)
  (show-paren-mode 1)
  (setq show-paren-delay 0)

  ;; Editing
  (electric-pair-mode 1)
  (delete-selection-mode 1)
  ;; Auto-revert buffers when files change on disk (e.g., git checkout).
  (global-auto-revert-mode 1)

  ;; Native macOS-style right-click context menus.
  (context-menu-mode 1)

  ;; Track recently opened files; surfaces in `consult-buffer'.
  (recentf-mode 1)
  ;; Remember cursor position in files across sessions.
  (save-place-mode 1))

;; Keybindings: text scaling. Bound to both Ctrl (universal muscle memory)
;; and Meta (Mac convention for Cmd-+, Cmd--, Cmd-0).
(use-package emacs
  :ensure nil
  :bind (("C-=" . text-scale-increase)
         ("C-+" . text-scale-increase)
         ("C--" . text-scale-decrease)
         ("C-0" . text-scale-adjust)
         ("M-=" . text-scale-increase)
         ("M-+" . text-scale-increase)
         ("M--" . text-scale-decrease)
         ("M-0" . text-scale-adjust)))

;; Scrolling
(use-package ultra-scroll
  :init
  (setq scroll-conservatively 3
        scroll-margin 0)
  :config
  (ultra-scroll-mode 1))


;;; -- macOS integration --

(use-package emacs
  :ensure nil
  :when (eq system-type 'darwin)
  :config
  ;; Use Command as Meta -- the ergonomic choice on Mac.
  (setq ns-command-modifier 'meta
        ns-option-modifier  'none)

  ;; Don't pop up new frames when opening files.
  (setq ns-pop-up-frames nil)

  ;; Keep the menu bar (it's native on macOS and expected).
  (menu-bar-mode 1))

;; Inherit PATH and other env vars from the user's shell.
;; Essential on macOS where GUI apps don't get the shell environment.
(use-package exec-path-from-shell
  :demand t
  :when (eq system-type 'darwin)
  :config
  (exec-path-from-shell-initialize))


;;; -- Themes --

;; Three theme packs available; switch with `M-x mzacuna/apply-theme'.
(use-package modus-themes
  :demand t
  :config
  (setq modus-themes-italic-constructs t
        modus-themes-bold-constructs t)
  (load-theme 'modus-vivendi :no-confirm))

(use-package ef-themes)
(use-package doom-themes)


;;; -- Font ---

(use-package emacs
  :ensure nil
  :config
  (let ((mono "JetBrainsMono Nerd Font")
        (vari "Charter")
        (size 180))
    ;; Default face: absolute size, set via frame alist for new frames AND
    ;; via set-face-attribute for the current frame.
    (add-to-list 'default-frame-alist `(font . ,(format "%s-%d" mono (/ size 10))))
    (set-face-attribute 'default nil :family mono :height size)
    ;; variable-pitch and fixed-pitch: family-only, with relative height.
    ;; This makes text-scale-adjust scale them proportionally.
    (set-face-attribute 'fixed-pitch    nil :family mono :height 1.0)
    (set-face-attribute 'variable-pitch nil :family vari :height 1.4444)))

;; mixed-pitch reads `fix-height' from the `default' face, which captures
;; an absolute integer (e.g. 180). That breaks `text-scale-adjust' in
;; mixed-pitch buffers — code blocks don't scale because they're remapped
;; to an absolute height. This advice redirects only that one call to
;; read from the `fixed-pitch' face instead, where we keep a relative
;; height (1.0). Both prose and code then scale with `text-scale-adjust'.
(defun mzacuna/mixed-pitch--read-fix-height-from-fixed-pitch (orig-fn &rest args)
  "Around-advice for `mixed-pitch-mode' to make `fix-height' relative."
  (cl-letf* ((orig-face-attribute (symbol-function 'face-attribute))
             ((symbol-function 'face-attribute)
              (lambda (face attr &rest rest)
                (if (and (eq face 'default) (eq attr :height))
                    (apply orig-face-attribute 'fixed-pitch attr rest)
                  (apply orig-face-attribute face attr rest)))))
    (apply orig-fn args)))

(use-package mixed-pitch
  :hook (text-mode . mixed-pitch-mode)
  :custom
  (mixed-pitch-set-height t)
  :config
  (advice-add 'mixed-pitch-mode :around
              #'mzacuna/mixed-pitch--read-fix-height-from-fixed-pitch))


;;; Visual (other)

;; Highlight current line on programming buffers.
(use-package hl-line
  :ensure nil
  :hook (prog-mode . hl-line-mode))


;;; -- Minibuffer completion --

;; Vertico: minimal, vertical completion UI.
(use-package vertico
  :custom
  (vertico-cycle t)
  :init
  (vertico-mode 1)
  :config
  ;; Built into Emacs 31; advice needed in 30 to show the CRM separator
  ;; visibly when reading multiple candidates.
  (when (< emacs-major-version 31)
    (advice-add #'completing-read-multiple :filter-args
                (lambda (args)
                  (cons (format "[CRM%s] %s"
                                (string-replace "[ \t]*" "" crm-separator)
                                (car args))
                        (cdr args))))))

;; Orderless: space-separated completion components, in any order.
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; Marginalia: rich annotations in the minibuffer.
(use-package marginalia
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))
  :init
  (marginalia-mode 1))

;; Consult: enhanced commands built on completing-read.
(use-package consult
  :bind (("C-x b"   . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("M-g g"   . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("M-s r"   . consult-ripgrep)
         ("M-s l"   . consult-line)))

;; Embark: act on whatever is at point or in the minibuffer.
(use-package embark
  :bind (("C-."   . embark-act)
         ("C-;"   . embark-dwim)
         ("C-h B" . embark-bindings)))

;; Bridge between embark and consult, e.g., for editing search results.
(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; wgrep: edit consult-ripgrep results in place; save to apply to all files.
(use-package wgrep)


;;; -- In-buffer completion --

;; Corfu: popup completion-at-point UI.
(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-cycle t)
  ;; Permissive: don't close the popup when there's no match, just on
  ;; the separator. Gives more time to backspace and try again.
  (corfu-quit-no-match 'separator)
  :hook
  ;; Documentation popup for the currently-highlighted completion candidate.
  (corfu-mode . corfu-popupinfo-mode)
  :init
  (global-corfu-mode 1))

;; Cape: additional completion-at-point backends.
;; cape-capf-buster is used in the lsp-mode setup below to keep completion
;; candidates consistent when the prefix changes mid-symbol.
(use-package cape
  :config
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))


;;; -- Keybinding discoverability --

;; which-key is built into Emacs 30. No need to install.
(use-package which-key
  :ensure nil
  :config
  (which-key-mode 1))


;;; -- Version control --

(use-package magit
  :bind ("C-c g" . magit-status))


;;; -- LSP --

;; emacs-lsp-booster must be installed and on PATH.
;; It wraps LSP server processes to handle JSON parsing off the Emacs thread,
;; and requires lsp-use-plists=t (set via LSP_USE_PLISTS in early-init.el).
(defun lsp-booster--advice-json-parse (old-fn &rest args)
  "Try to parse bytecode instead of json."
  (or (when (equal (following-char) ?#)
        (let ((bytecode (read (current-buffer))))
          (when (byte-code-function-p bytecode)
            (funcall bytecode))))
      (apply old-fn args)))

(defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
  "Prepend emacs-lsp-booster command to lsp CMD."
  (let ((orig-result (funcall old-fn cmd test?)))
    (if (and (not test?)
             (not (file-remote-p default-directory))
             lsp-use-plists
             (not (functionp 'json-rpc-connection))
             (executable-find "emacs-lsp-booster"))
        (progn
          (when-let ((command-from-exec-path (executable-find (car orig-result))))
            (setcar orig-result command-from-exec-path))
          (message "Using emacs-lsp-booster for %s!" orig-result)
          (cons "emacs-lsp-booster" orig-result))
      orig-result)))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  ;; Per-language hooks
  :hook ((typescript-ts-mode . lsp-deferred)
         (tsx-ts-mode         . lsp-deferred)
         (js-ts-mode          . lsp-deferred)
         (python-ts-mode      . lsp-deferred)
         (rust-ts-mode        . lsp-deferred)
         (nix-ts-mode         . lsp-deferred)
         (lsp-mode            . lsp-enable-which-key-integration)
         (lsp-completion-mode . mzacuna/lsp-mode-setup-completion))
  :init
  (setq lsp-keymap-prefix "C-c l"
        lsp-use-plists t)
  ;; Wire up lsp-booster. The advice functions are no-ops if the
  ;; emacs-lsp-booster binary is not found on PATH.
  (advice-add (if (progn (require 'json) (fboundp 'json-parse-buffer))
                  'json-parse-buffer
                'json-read)
              :around #'lsp-booster--advice-json-parse)
  (advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command)
  ;; Completion: hand off to Corfu via capf rather than lsp-mode's own UI.
  (defun mzacuna/lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
          '(orderless))
    ;; Wrap lsp-completion-at-point with cape-capf-buster for consistency
    ;; when the completion prefix changes mid-symbol.
    (setq-local completion-at-point-functions
                (list (cape-capf-buster #'lsp-completion-at-point)
                      #'cape-file
                      #'cape-dabbrev)))
  :config
  (setq lsp-completion-provider :none          ; Corfu handles completion
        lsp-idle-delay 0.5
        lsp-keep-workspace-alive nil            ; shut down server with last buffer
        lsp-headerline-breadcrumb-enable nil    ; handled by mode line / consult-imenu
        lsp-modeline-code-actions-enable nil
        lsp-modeline-diagnostics-enable nil
        lsp-signature-auto-activate t
        lsp-eldoc-enable-hover t
        ;; For .nix files, prefer nixd over nil. nil's default priority is
        ;; higher and would otherwise win. Harmless if nil isn't installed.
        lsp-disabled-clients '((nix-ts-mode . nix-nil))))

;; lsp-ui: sideline diagnostics, hover docs, peek definitions.
(use-package lsp-ui
  :after lsp-mode
  :config
  (setq lsp-ui-sideline-enable t
        lsp-ui-sideline-show-diagnostics t
        lsp-ui-sideline-show-code-actions nil   ; too noisy inline; use C-c l a
        lsp-ui-doc-enable t
        lsp-ui-doc-position 'at-point))

;; lsp-pyright: integrates the Pyright/basedpyright type checker as a Python LSP.
;; basedpyright is a community fork with stricter defaults and additional
;; checks; it's the same protocol as pyright, just a different binary.
(use-package lsp-pyright
  :custom
  (lsp-pyright-langserver-command "basedpyright")
  :hook (python-ts-mode . (lambda ()
                            (require 'lsp-pyright)
                            (lsp-deferred))))


;;; -- Format-on-save --

;; Apheleia: asynchronous code formatting on save. Doesn't block Emacs while
;; the formatter runs. Handles Prettier (TS/JS), Black/Ruff (Python),
;; rustfmt (Rust), nixfmt (Nix), gofmt (Go), and many others uniformly.
(use-package apheleia
  :config
  (apheleia-global-mode 1))


;;; -- Tree-sitter --

;; treesit-auto: automatically install and use tree-sitter grammars.
;; Grammars are compiled on-demand and stored in
;; ~/.config/emacs/tree-sitter/.
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))


;;; -- Language modes --

;; Nix major mode using tree-sitter.
(use-package nix-ts-mode
  :mode "\\.nix\\'")

;; Markdown
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"        . markdown-mode)
         ("\\.markdown\\'"  . markdown-mode))
  :init (setq markdown-command "multimarkdown")
  :bind (:map markdown-mode-map
              ("C-c C-e" . markdown-do)))


;;; -- Writing --

;; Distraction-free writing with centered, soft-wrapped text.
(use-package olivetti
  :hook (text-mode . olivetti-mode)
  :config
  ;; This crashes and burns if it's an integer because something in Olivetti
  ;; doesn't expect that the face height would be a lambda (see "Font").
  ;; (I'm not actually using a lambda height anymore but I'll keep it decimal.)
  (setq olivetti-body-width 0.68))

;; Spell-checking. Jinx is a fast, modern replacement for flyspell.
(use-package jinx
  :bind (("C-c s c" . jinx-correct)
         ("C-c s l" . jinx-languages)
         ("C-c s d" . mzacuna/jinx-save-word-dir-local)
         ("C-c s p" . mzacuna/jinx-save-word-personal))
  :hook (emacs-startup . global-jinx-mode)
  :custom
  (jinx-languages "en_US es_MX")
  :config
  ;; Helper function
  (defun mzacuna/jinx--act-on-word (action-fn success-message)
    "Extract Jinx word, check validity, and execute ACTION-FN."
    (if-let* ((bounds (jinx--bounds-of-word))
              (word (buffer-substring-no-properties (car bounds) (cdr bounds))))
        (if (jinx--word-valid-p word)
            (message "'%s' is already spelled correctly!" word)
          (progn
            ;; Run whatever specific saving logic we passed to this helper.
            (funcall action-fn word)
            ;; Universally clear the squiggly lines.
            (jinx--recheck-overlays)
            ;; Print the success message.
            (message success-message word)))
      (user-error "No word found at point.")))

  ;; Directory-local save
  (defun mzacuna/jinx-save-word-dir-local ()
    "Save Jinx word at point to directory-local variables if misspelled."
    (interactive)
    (mzacuna/jinx--act-on-word
     (lambda (word)
       (jinx--save-dir t nil word)
       (dolist (buf (buffer-list))
         (when (and (buffer-file-name buf)
                    (string-suffix-p ".dir-locals.el" (buffer-file-name buf))
                    (buffer-modified-p buf))
           (with-current-buffer buf (save-buffer)))))
     "Added '%s' to directory-local Jinx words!"))

  ;; Personal dictionary save
  (defun mzacuna/jinx-save-word-personal ()
    "Save Jinx word at point to the primary personal dictionary if misspelled."
    (interactive)
    (mzacuna/jinx--act-on-word
     (lambda (word)
       (jinx--save-personal t ?@ word))
     "Added '%s' to personal dictionary!")))


;;; -- Persist minibuffer history --

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1))


;;; init.el ends here

;; Local Variables:
;; no-byte-compile: t
;; no-native-compile: t
;; no-update-autoloads: t
;; End:
