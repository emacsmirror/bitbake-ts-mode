;;; bitbake-ts-mode.el --- A major mode to use bitbake tree-sitter -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Sukbeom Kim

;; Author: Jason Kim <sukbeom.kim@gmail.com>
;; Maintainer: Jason Kim <sukbeom.kim@gmail.com>
;; Created: September 8, 2024
;; Keywords: bitbake, tree-sitter, languages
;; Version: 0.0.1
;; Homepage: https://github.com/seokbeomKim/bitbake-ts-mode
;; Package-Requires: ((emacs "29.1"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Setup:

;; 1. install tree-sitter parser for Yocto bitbake
;; (add-to-list
;;  'treesit-language-source-alist
;;  '(bitbake "https://github.com/tree-sitter-grammars/tree-sitter-bitbake"))
;;
;; 2. install bitbake-ts-mode major mode
;; (require 'bitbake-ts-mode)

;;; Commentary:

;; For now, the package does not support indentation rule, but only supports
;; syntax highlighting and imenu integration.

;;; Code:
(require 'treesit)
(eval-when-compile (require 'rx))

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-node-child-by-field-name "treesit.c")

(defconst bitbake-ts-mode--treesit-keywords
  '("inherit" "require" "include" "INHERIT"))

(defvar bitbake-ts-font-lock-rules
    `(:language bitbake
      :override t
      :feature attribute
      ((attribute) @font-lock-builtin-face)

      :language bitbake
      :override t
      :feature identifier
      ((identifier) @font-lock-variable-keyword-face)

      :language bitbake
      :override t
      :feature string_content
      ((string_content) @font-lock-string-face)

      :language bitbake
      :override t
      :feature comment
      ((comment) @font-lock-comment-face)

      :language bitbake
      :override t
      :feature keyword
      ([,@bitbake-ts-mode--treesit-keywords] @font-lock-keyword-face)
      ))

(defcustom bitbake-ts-mode-indent-offset 8
  "Number of spaces for each indentation step in `bitbake-ts-mode'."
  :type 'natnum
  :safe 'natnump)

(defun bitbake-ts-imenu-identifier-name-function (node)
  "A function to return the name of identifier `NODE'."
  (let ((name (treesit-node-text node)))
    (if (bitbake-ts-imenu-identifier-node-p node)
        (concat name " / " (treesit-node-text node)))
      name))

(defun bitbake-ts-imenu-identifier-node-p (node)
  "A function to check whether the `NODE' is identifier."
  (string-match-p "^identifier$" (treesit-node-type node)))

(defun bitbake-ts-imenu-directive-name-function (node)
  "A function to obtain the name of directive `NODE'."
  (let ((name (treesit-node-text node)))
    (if (bitbake-ts-imenu-directive-node-p node)
        (concat name " / " (treesit-node-text node)))
      name))

(defun bitbake-ts-imenu-directive-node-p (node)
  "A function to check whether the `NODE' is directive."
  (string-match-p "_directive$" (treesit-node-type node)))

;;;###autoload
(define-derived-mode bitbake-ts-mode prog-mode "bitbake"
  "Major mode for editing Yocto recipe, powered by tree-sitter."

  (when (treesit-ready-p 'bitbake)
    (treesit-parser-create 'bitbake)

    ;; Define a list of features of what it is going to be highlighted
    (setq-local treesit-font-lock-feature-list
                '((comment)
                  (keyword)
                  (identifier attribute string_content)
                  ))

    ;; Font-lock
    (setq-local treesit-font-lock-settings
                (apply #'treesit-font-lock-rules
                       bitbake-ts-font-lock-rules))

    ;; Comments
    (setq-local comment-start "# ")

    ;; Imenu
    (setq-local treesit-simple-imenu-settings
              `(("Directive" bitbake-ts-imenu-directive-node-p nil bitbake-ts-imenu-directive-name-function)
                ("Identifier" bitbake-ts-imenu-identifier-node-p nil bitbake-ts-imenu-identifier-name-function)))

    ;; Which function
    (setq-local which-func-functions nil)

    ;; Indentation
    (setq-local indent-tabs-mode nil)

    (treesit-major-mode-setup)))

(when (treesit-ready-p 'bitbake)
  (add-to-list 'auto-mode-alist '("\\.bb?\\'" . bitbake-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.bbappend?\\'" . bitbake-ts-mode)))

(provide 'bitbake-ts-mode)
;;; bitbake-ts-mode.el ends here
