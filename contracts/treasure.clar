;; Treasure Guardian Contract


;; ==================================
;; Fundamental Storage Definitions
;; ==================================

;; Master counter for all treasures in the collection
(define-data-var treasure-count uint u0)

;; Primary repository of treasure information and metadata
(define-map treasure-repository
  { treasure-sequence: uint }  ;; Each treasure is assigned a unique sequential identifier
  {
    name: (string-ascii 64),           ;; Official name of the treasure
    custodian: principal,              ;; Principal who currently possesses custodial rights
    dimension: uint,                   ;; Numerical representation of treasure's physical characteristics
    inception-block: uint,             ;; Block height at treasure registration
    lore: (string-ascii 128),          ;; Historical or contextual information about the treasure
    classifications: (list 10 (string-ascii 32))  ;; Categorical classifications for the treasure
  }
)

;; Permission matrix determining which principals can interact with specific treasures
(define-map permission-matrix
  { treasure-sequence: uint, subject: principal }  ;; Maps treasures to authorized subjects
  { permitted: bool }                              ;; Permission status flag
)

;; ==================================
;; Essential Constants
;; ==================================

;; Authority principal with highest privilege level
(define-constant SOVEREIGN tx-sender)  

;; Response codes for operational outcomes
(define-constant ERR-TREASURE-NONEXISTENT (err u301))      ;; Target treasure does not exist in repository
(define-constant ERR-TREASURE-PREEXISTING (err u302))      ;; Attempted to register an already existing treasure
(define-constant ERR-DIMENSION-CONSTRAINT (err u304))      ;; Dimension value violates established constraints
(define-constant ERR-AUTHORITY-VIOLATION (err u305))       ;; Operation attempted by unauthorized principal
(define-constant ERR-INVALID-RECIPIENT (err u306))         ;; Target recipient is invalid for the operation
(define-constant ERR-SOVEREIGN-RESTRICTED (err u307))      ;; Operation restricted to sovereign principal only
(define-constant ERR-PERMISSION-ABSENT (err u308))         ;; Subject lacks required permissions
(define-constant ERR-NAME-CONSTRAINT (err u303))           ;; Name format violates established constraints


;; ==================================
;; Utility Functions
;; ==================================

;; Determines if the specified treasure exists in the repository
(define-private (treasure-registered? (treasure-sequence uint))
  (is-some (map-get? treasure-repository { treasure-sequence: treasure-sequence }))
)

;; Verifies if the specified principal is the custodian of a treasure
(define-private (is-custodian? (treasure-sequence uint) (subject principal))
  (match (map-get? treasure-repository { treasure-sequence: treasure-sequence })
    treasure-data (is-eq (get custodian treasure-data) subject)
    false
  )
)

;; Retrieves the dimension property of a specified treasure
(define-private (extract-dimension (treasure-sequence uint))
  (default-to u0 
    (get dimension 
      (map-get? treasure-repository { treasure-sequence: treasure-sequence })
    )
  )
)

;; Validates a single classification string
(define-private (is-classification-valid? (classification (string-ascii 32)))
  (and 
    (> (len classification) u0)     ;; Must contain at least one character
    (< (len classification) u33)    ;; Must not exceed 32 characters
  )
)

;; Validates the complete set of treasure classifications
(define-private (validate-classifications (classifications (list 10 (string-ascii 32))))
  (and
    (> (len classifications) u0)                                           ;; Must have at least one classification
    (<= (len classifications) u10)                                         ;; Cannot exceed 10 classifications
    (is-eq (len (filter is-classification-valid? classifications)) 
           (len classifications))                                          ;; All classifications must be valid
  )
)

;; Validates string length against minimum and maximum constraints
(define-private (validate-text-bounds (text (string-ascii 64)) (min-chars uint) (max-chars uint))
  (and 
    (>= (len text) min-chars)
    (<= (len text) max-chars)
  )
)
