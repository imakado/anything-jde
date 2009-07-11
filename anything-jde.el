;;; anything-jde.el --

(require 'jde)
(require 'anything)

;;; Configuration sample
;; (add-hook 'jde-mode-hook
;;           '(lambda ()
;;              (define-key jde-mode-map (kbd "C-M-i") 'anything-jde-complete)
;;              ))

(defvar anything-source-jde-complete
  `((name . "jde completions")
    (candidates . anything-jde-get-completion-list)
    (action . (("Insert" . jde-complete-insert-completion)))))

(defun anything-jde-complete ()
  (interactive)
  (anything 'anything-source-jde-complete))

(defun anything-jde-get-completion-list ()
  (with-current-buffer anything-current-buffer
    (let ((pair (jde-parse-java-variable-at-point))
          jde-parse-attempted-to-import)
      (if pair
          (condition-case err
              (anything-jde-completion-list (jde-complete-get-pair pair nil))
            (error (condition-case err
                       (anything-jde-completion-list (jde-complete-get-pair pair t)
                                                     completion-type))
                   (error (message "%s" (error-message-string err)))))
        (anything-run-after-quit
         (lambda ()
           (message "No completion at this point")))))))

(defun anything-jde-completion-list (pair)
  (let ((access (jde-complete-get-access pair))
        completion-list)
    (progn
      (if access
          (setq completion-list
                (jde-complete-find-completion-for-pair pair nil access))
        (setq completion-list (jde-complete-find-completion-for-pair pair)))
      ;;if the completion list is nil check if the method is in the current
      ;;class(this)
      (if (null completion-list)
          (setq completion-list (jde-complete-find-completion-for-pair
                                 (list (concat "this." (car pair)) "")
                                 nil jde-complete-private)))
      ;;if completions is still null check if the method is in the
      ;;super class
      (if (null completion-list)
          (setq completion-list (jde-complete-find-completion-for-pair
                                 (list (concat "super." (car pair)) "")
                                 nil jde-complete-protected)))
      (when completion-list
        completion-list))))

(unless (fboundp 'anything-run-after-quit)
  (defun anything-run-after-quit (function &rest args)
    "Perform an action after quitting `anything'.
The action is to call FUNCTION with arguments ARGS."
    (setq anything-quit t)
    (apply 'run-with-idle-timer 0 nil function args)
    (anything-exit-minibuffer)))

(provide 'anything-jde)
