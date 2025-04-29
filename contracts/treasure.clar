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

;; Increments the master treasure counter and returns previous value
(define-private (advance-treasure-counter)
  (let ((current-value (var-get treasure-count)))
    (var-set treasure-count (+ current-value u1))
    (ok current-value)
  )
)

;; ==================================
;; Public Operations
;; ==================================

;; Register a new treasure in the collection
(define-public (register-treasure (name (string-ascii 64)) (dimension uint) (lore (string-ascii 128)) (classifications (list 10 (string-ascii 32))))
  (let
    (
      (new-sequence (+ (var-get treasure-count) u1))  ;; Generate sequence number for new treasure
    )
    ;; Enforce input constraints
    (asserts! (and (> (len name) u0) (< (len name) u65)) ERR-NAME-CONSTRAINT)      ;; Name must be 1-64 characters
    (asserts! (and (> dimension u0) (< dimension u1000000000)) ERR-DIMENSION-CONSTRAINT)  ;; Dimension must be reasonable
    (asserts! (and (> (len lore) u0) (< (len lore) u129)) ERR-NAME-CONSTRAINT)     ;; Lore must be 1-128 characters
    (asserts! (validate-classifications classifications) ERR-NAME-CONSTRAINT)       ;; Classifications must be valid

    ;; Record the treasure in the repository
    (map-insert treasure-repository
      { treasure-sequence: new-sequence }
      {
        name: name,
        custodian: tx-sender,
        dimension: dimension,
        inception-block: block-height,
        lore: lore,
        classifications: classifications
      }
    )

    ;; Grant initial permissions to custodian
    (map-insert permission-matrix
      { treasure-sequence: new-sequence, subject: tx-sender }
      { permitted: true }
    )

    ;; Update the master counter
    (var-set treasure-count new-sequence)
    (ok new-sequence)  ;; Return the assigned sequence number
  )
)

;; Retrieve the lore associated with a specific treasure
(define-public (retrieve-lore (treasure-sequence uint))
  ;; Fetches the narrative description of a treasure
  (let
    (
      (treasure-data (unwrap! (map-get? treasure-repository { treasure-sequence: treasure-sequence }) ERR-TREASURE-NONEXISTENT))
    )
    (ok (get lore treasure-data))
  )
)

;; Verify if a subject has permissions for a specific treasure
(define-public (verify-subject-permission (treasure-sequence uint) (subject principal))
  ;; Returns true if the subject has permission for the treasure
  (let
    (
      (permission-data (map-get? permission-matrix { treasure-sequence: treasure-sequence, subject: subject }))
    )
    (ok (is-some permission-data))
  )
)

;; Count the number of classifications associated with a treasure
(define-public (count-classifications (treasure-sequence uint))
  ;; Returns the total number of classifications for a treasure
  (let
    (
      (treasure-data (unwrap! (map-get? treasure-repository { treasure-sequence: treasure-sequence }) ERR-TREASURE-NONEXISTENT))
    )
    (ok (len (get classifications treasure-data)))
  )
)

;; Validate if a name meets the required constraints
(define-public (validate-name (name (string-ascii 64)))
  ;; Checks if name length is within acceptable bounds (1-64 characters)
  (ok (and (> (len name) u0) (<= (len name) u64)))
)

;; Transfer custodial rights to another principal
(define-public (transfer-custodianship (treasure-sequence uint) (new-custodian principal))
  (let
    (
      (treasure-data (unwrap! (map-get? treasure-repository { treasure-sequence: treasure-sequence }) ERR-TREASURE-NONEXISTENT))
    )
    (asserts! (treasure-registered? treasure-sequence) ERR-TREASURE-NONEXISTENT)  ;; Verify treasure exists
    (asserts! (is-eq (get custodian treasure-data) tx-sender) ERR-AUTHORITY-VIOLATION)  ;; Only current custodian can transfer

    ;; Update the repository with new custodian
    (map-set treasure-repository
      { treasure-sequence: treasure-sequence }
      (merge treasure-data { custodian: new-custodian })
    )
    (ok true)
  )
)

;; Update treasure metadata and properties
(define-public (update-treasure (treasure-sequence uint) (new-name (string-ascii 64)) (new-dimension uint) (new-lore (string-ascii 128)) (new-classifications (list 10 (string-ascii 32))))
  (let
    (
      (treasure-data (unwrap! (map-get? treasure-repository { treasure-sequence: treasure-sequence }) ERR-TREASURE-NONEXISTENT))
    )
    ;; Validation conditions
    (asserts! (treasure-registered? treasure-sequence) ERR-TREASURE-NONEXISTENT)  ;; Verify treasure exists
    (asserts! (is-eq (get custodian treasure-data) tx-sender) ERR-AUTHORITY-VIOLATION)  ;; Only custodian can update
    (asserts! (and (> (len new-name) u0) (< (len new-name) u65)) ERR-NAME-CONSTRAINT)  ;; Validate new name
    (asserts! (and (> new-dimension u0) (< new-dimension u1000000000)) ERR-DIMENSION-CONSTRAINT)  ;; Validate new dimension
    (asserts! (and (> (len new-lore) u0) (< (len new-lore) u129)) ERR-NAME-CONSTRAINT)  ;; Validate new lore
    (asserts! (validate-classifications new-classifications) ERR-NAME-CONSTRAINT)  ;; Validate new classifications

    ;; Update the treasure properties
    (map-set treasure-repository
      { treasure-sequence: treasure-sequence }
      (merge treasure-data { 
        name: new-name, 
        dimension: new-dimension, 
        lore: new-lore, 
        classifications: new-classifications 
      })
    )
    (ok true)
  )
)

;; Remove a treasure from the collection
(define-public (retire-treasure (treasure-sequence uint))
  (let
    (
      (treasure-data (unwrap! (map-get? treasure-repository { treasure-sequence: treasure-sequence }) ERR-TREASURE-NONEXISTENT))
    )
    (asserts! (treasure-registered? treasure-sequence) ERR-TREASURE-NONEXISTENT)  ;; Verify treasure exists
    (asserts! (is-eq (get custodian treasure-data) tx-sender) ERR-AUTHORITY-VIOLATION)  ;; Only custodian can retire

    ;; Remove the treasure from the repository
    (map-delete treasure-repository { treasure-sequence: treasure-sequence })
    (ok true)
  )
)

