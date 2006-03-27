;;; rails-scripts.el --- emacs-rails integraions with rails script/* scripts

;; Copyright (C) 2006 Galinsky Dmitry <dima dot exe at gmail dot com>

;; Authors: Galinsky Dmitry <dima dot exe at gmail dot com>,
;;          Rezikov Peter <crazypit13 (at) gmail.com>

;; Keywords: ruby rails languages oop
;; $URL: svn+ssh://crazypit@rubyforge.org/var/svn/emacs-rails/trunk/rails-core.el $
;; $Id: rails-navigation.el 23 2006-03-27 21:35:16Z crazypit $

;;; License

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

(defvar rails-generation-buffer-name "*RailsGeneration*")

(defun rails-run-script (script buffer parameters &optional message-format)
  "Run rails script with ``parameters'' in ``buffer''"
  (rails-core:with-root
   (root)
   (let ((default-directory root))
     (rails-logged-shell-command
      (format "ruby %s %s"
	      (format "script/%s " script)
	      (apply #'concat
		     (mapcar #'(lambda (str)
				 (if str (concat str " ") ""))
			     parameters)))
      buffer))
   (when message-format
     (message message-format (capitalize (first parameters))
	      (second parameters)))))

;;;;;;;;;; Destroy stuff ;;;;;;;;;;


(defun rails-destroy (&rest parameters)
  "Running destroy script"
  (rails-run-script "destroy" rails-generation-buffer-name parameters
		    "%s %s destroyed."))

(defun rails-destroy-controller (&optional controller-name)
  (interactive
   (list (completing-read "Controller name: " (list->alist (rails-core:controllers t)))))
  (when (string-not-empty controller-name)
    (rails-destroy "controller" controller-name)))

(defun rails-destroy-model (&optional model-name)
  (interactive (list (completing-read "Model name: " (list->alist (rails-core:models)))))
    (when (string-not-empty model-name)
      (rails-destroy "model" model-name)))

(defun rails-destroy-scaffold (&optional scaffold-name)
  ;; buggy
  (interactive "MScaffold name: ")
  (when (string-not-empty scaffold-name)
    (rails-destroy "scaffold" scaffold-name)))


;;;;;;;;;; Generators stuff ;;;;;;;;;;

(defun rails-generate (&rest parameters)
  "Generate with ``parameters''"
  (rails-run-script "generate" rails-generation-buffer-name parameters
		    "%s %s generated.")
  ;(switch-to-buffer-other-window rails-generation-buffer-name)
  )


(defun rails-generate-controller (&optional controller-name actions)
  "Generate controller and open controller file"
  (interactive (list
		(completing-read "Controller name (use autocomplete) : "
				 (list->alist (rails-core:controllers-ancestors)))
		(read-string "Actions (or return to skip): ")))
    (when (string-not-empty controller-name)
	(rails-generate "controller" controller-name actions)
	(rails-core:find-file (rails-controller-file controller-name))))

(defun rails-generate-model (&optional model-name)
  "Generate model and open model file"
  (interactive
   (list (completing-read "Model name: " (list->alist (rails-core:models-ancestors)))))
  (when (string-not-empty model-name)
    (rails-generate "model" model-name)
    (rails-core:find-file (rails-model-file model-name))))


(defun rails-generate-scaffold (&optional model-name controller-name actions)
  "Generate scaffold and open controller file"
  (interactive
   "MModel name: \nMController (or return to skip): \nMActions (or return to skip): ")
  (when (string-not-empty model-name)
    (if (string-not-empty controller-name)
	(progn
	  (rails-generate "scaffold" model-name controller-name actions)
	  (rails-core:find-file (rails-controller-file controller-name)))
      (progn
	(rails-generate "scaffold" model-name)
	(rails-core:find-file (rails-controller-file model-name))))))

(defun rails-generate-migration (migration-name)
  "Generate new migration and open migration file"
  (interactive "MMigration name: ")
  (when (string-not-empty migration-name)
    (rails-generate "migration" migration-name)
    (rails-core:find-file
     (save-excursion
       (set-buffer rails-generation-buffer-name)
       (goto-line 2)
       (search-forward-regexp "\\(db/migrate/[0-9a-z_]+.rb\\)")
       (match-string 1)))))

;;;;;;;;;; Rails create project ;;;;;;;;;;

(defun rails-create-project (dir)
  "Create new project in ``dir'' directory"
  (interactive "FNew project directory: ")
  (shell-command (concat "rails " dir)
		 rails-generation-buffer-name)
  (flet ((rails-core:root () (concat dir "/") ))
    (rails-log-add
     (format "\nCreating project %s\n%s"
	     dir (buffer-string-by-name rails-generation-buffer-name))))
  (find-file dir))


;;;;;;;;;; Shells ;;;;;;;;;;

(defun rails-run-console ()
  (interactive)
  (run-ruby (rails-core:file "script/console")))

(defun rails-run-breakpointer ()
  (interactive)
  (run-ruby (rails-core:file "script/breakpointer")))

(provide 'rails-scripts)