(require 'package)
(package-initialize)
(unless package-archive-contents
  (add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t)
  (add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
  (package-refresh-contents))
(dolist (pkg '(org))
  (unless (package-installed-p pkg)
    (package-install pkg)))

(require 'org)
;; (require 'oc-csl)
(require 'ox-publish)
;; (require 'projectile)

(require 'ox-latex)
(add-to-list 'org-latex-classes
						 '("ltxdoc"
							 "\\documentclass{ltxdoc}"
							 ("\\section{%s}" . "\\section*{%s}")
							 ("\\subsection{%s}" . "\\subsection*{%s}")
							 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
							 ("\\paragraph{%s}" . "\\paragraph*{%s}")
							 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

(setq
 org-latex-hyperref-template ""
 ;; org-confirm-babel-evaluate nil
 org-hide-emphasis-markers t
 org-latex-listings 'minted
 org-latex-packages-alist '(("" "minted"))
 )

;; (defun publish-html-and-patch (plist filename pub-dir)
;; 	"Export a html file then patch it by reversing lines"
;; 	(let ((outfile (org-html-publish-to-html plist filename pub-dir)))
;; 		(shell-command
;; 		 (format "sed -i 's/Wang, H\\./<strong>Wang, H.<\\/strong>/' %s"
;; 						 outfile (file-name-sans-extension outfile)))))

;; (defvar OS--publish-project-alist
;;   (list
;;    (list "myweb"
;;          :base-directory "./"
;;          :exclude (regexp-opt '("others" "style/others"))
;;          :base-extension "org"
;;          :recursive t
;;          :publishing-directory "./public"
;;          ;; :publishing-function 'org-html-publish-to-html
;;          :publishing-function 'publish-html-and-patch)
;;    (list "attachments"
;;          :base-directory "./"
;;          :exclude (regexp-opt '("public" "others" "style/others"))
;;          ;; :include '("CNAME" "keybase.txt" "LICENSE" ".nojekyll" "publish.el")
;;          :recursive t
;;          :base-extension (regexp-opt '("jpg" "gif" "png" "svg" "css" "pdf" "html"))
;;          :publishing-directory "./public"
;;          :publishing-function 'org-publish-attachment)
;; 	 ))

;; (defun OS-publish-all ()
;; 	(interactive)
;; 	(let ((make-backup-files nil)
;; 				(org-publish-project-alist OS--publish-project-alist)
;; 				(org-html-htmlize-output-type 'css)
;; 				(org-cite-csl-styles-dir (expand-file-name "style/" (projectile-project-root))))
;; 		(org-publish-all)
;; 		))
