;; # Experience configuration
;; Font
(set-face-attribute 'default nil :height 190)

;; Always show tabs
(tab-bar-mode +1)

;; Disable toolbar
(tool-bar-mode -1)

;; Allow hash to be entered  
(defun co-insert-octothorpe ()
  "Insert an octothrpe at the current character position"
  (interactive)
  (insert "#"))
(global-set-key (kbd "M-3") 'co-insert-octothorpe)

;; Smooth scrolling (why is this not a default?)
(pixel-scroll-precision-mode +1)

;; Smooth resizing (why is this not a default?)
(setq frame-resize-pixelwise t)

;; # Package manager

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(package-initialize)
(package-refresh-contents)

;; # Vim commands
;; Download Evil
(unless (package-installed-p 'evil)
  (package-install 'evil))

;; Enable Evil
(require 'evil)
(evil-mode 1)

(evil-set-leader nil (kbd "SPC"))

;; # Evaluation keybinds
;; Eval region
(evil-define-key 'visual 'global (kbd "<leader> e r") 'eval-region)
;; Eval expression
(evil-define-key '(normal visual) 'global (kbd "<leader> e e") 'eval-expression)
;; Eval buffer
(evil-define-key '(normal visual) 'global (kbd "<leader> e b") 'eval-buffer)

;; # Tab manipulation
(defun co-tab-open-shell ()
  "Open a new tab as a shell"
  (interactive)
  (tab-new)
  (eshell t))

(evil-define-key '(normal emacs) 'global (kbd "<leader> t e") 'co-tab-open-shell)

(defun co-tab-open-dired ()
  "Open a new tab with dired"
  (interactive)
  (tab-new)
  (dired))

(evil-define-key '(normal emacs) 'global (kbd "<leader> t d") 'co-tab-open-dired)

(defun co-close-tab ()
  "Close a tab and kill the buffer"
  (interactive)
  (kill-buffer)
  (tab-close))

(evil-define-key '(normal emacs) 'global (kbd "<leader> t c") 'co-close-tab)

;; # Eshell

;; Shorhands
(defalias 'e 'find-file)

;; Environment variables

;; # Buffers
(evil-define-key '(normal emacs) 'global (kbd "<leader> b k") 'kill-current-buffer)


;; # Start out in eshell
(add-hook 'emacs-startup-hook 'eshell)


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(evil)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
