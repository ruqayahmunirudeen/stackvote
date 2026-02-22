;; stackvote.clar
;; A decentralized governance & voting contract on Stacks

;; --------------------------------
;; ERRORS
;; --------------------------------
(define-constant ERR_NOT_ADMIN u100)
(define-constant ERR_NOT_FOUND u101)
(define-constant ERR_ALREADY_VOTED u102)
(define-constant ERR_VOTING_CLOSED u103)
(define-constant ERR_NO_FUNDS u104)
(define-constant ERR_INVALID_AMOUNT u105)

;; --------------------------------
;; DATA VARIABLES
;; --------------------------------
(define-data-var owner principal tx-sender)
(define-data-var next-proposal-id uint u0)
(define-data-var total-proposals uint u0)
(define-data-var voter-reward-rate uint u2) ;; 2% reward for voters

(define-map proposals
  uint
  (tuple
    (creator principal)
    (title (string-ascii 128))
    (description (string-ascii 256))
    (for-votes uint)
    (against-votes uint)
    (total-staked uint)
    (deadline uint)
    (executed bool)
  )
)

(define-map votes
  (tuple (proposal-id uint) (voter principal))
  (tuple
    (support bool)
    (weight uint)
    (timestamp uint)
    (rewarded bool)
  )
)

(define-map deposits
  principal
  uint
)

;; --------------------------------
;; EVENTS (using data variables to track them)
;; --------------------------------


;; --------------------------------
;; PRIVATE HELPERS
;; --------------------------------
(define-private (only-owner)
  (if (is-eq tx-sender (var-get owner))
      (ok true)
      (err ERR_NOT_ADMIN))
)

;; Weight-based voting - deposit-based power
(define-private (get-weight (voter principal))
  (default-to u0 (map-get? deposits voter))
)

;; Reward calculation for participation
(define-private (calc-reward (weight uint))
  (/ (* weight (var-get voter-reward-rate)) u100)
)

;; --------------------------------
;; PUBLIC FUNCTIONS
;; --------------------------------

;; 1. Deposit STX to gain voting power
(define-public (deposit (amount uint))
  (if (> amount u0)
      (begin
        (try! (stx-transfer? amount tx-sender contract-caller))
        (map-set deposits tx-sender (+ amount (get-weight tx-sender)))
        (ok "Deposit successful"))
      (err ERR_INVALID_AMOUNT))
)

;; 2. Create new proposal
(define-public (create-proposal (title (string-ascii 128)) (description (string-ascii 256)) (duration uint))
  (let ((id (+ (var-get next-proposal-id) u1)))
    (asserts! (> (len title) u0) (err ERR_INVALID_AMOUNT))
    (asserts! (> (len description) u0) (err ERR_INVALID_AMOUNT))
    (asserts! (> duration u0) (err ERR_INVALID_AMOUNT))
    (map-set proposals id
      (tuple
        (creator tx-sender)
        (title title)
        (description description)
        (for-votes u0)
        (against-votes u0)
        (total-staked (get-weight tx-sender))
        (deadline (+ burn-block-height duration))
        (executed false)))
    (var-set next-proposal-id id)
    (var-set total-proposals (+ (var-get total-proposals) u1))
    (ok (tuple (proposal-id id) (creator tx-sender))))
)

;; 3. Vote for or against a proposal
(define-public (vote (proposal-id uint) (support bool))
  (let ((p (unwrap! (map-get? proposals proposal-id) (err ERR_NOT_FOUND))))
    (if (<= burn-block-height (get deadline p))
        (if (is-none (map-get? votes (tuple (proposal-id proposal-id) (voter tx-sender))))
            (let ((weight (get-weight tx-sender)))
              (if (> weight u0)
                  (begin
                    ;; record vote
                    (map-set votes (tuple (proposal-id proposal-id) (voter tx-sender))
                      (tuple
                        (support support)
                        (weight weight)
                        (timestamp burn-block-height)
                        (rewarded false)))
                    ;; add vote to proposal tally
                    (map-set proposals proposal-id
                      (tuple
                        (creator (get creator p))
                        (title (get title p))
                        (description (get description p))
                        (for-votes (if support (+ (get for-votes p) weight) (get for-votes p)))
                        (against-votes (if (not support) (+ (get against-votes p) weight) (get against-votes p)))
                        (total-staked (get total-staked p))
                        (deadline (get deadline p))
                        (executed (get executed p))))
                    (ok "Vote recorded"))
                  (err ERR_NO_FUNDS)))
            (err ERR_ALREADY_VOTED))
        (err ERR_VOTING_CLOSED)))
)

;; 4. Execute proposal (after deadline)
(define-public (execute-proposal (proposal-id uint))
  (let ((p (unwrap! (map-get? proposals proposal-id) (err ERR_NOT_FOUND))))
    (if (and (> burn-block-height (get deadline p)) (not (get executed p)))
        (let ((result (if (> (get for-votes p) (get against-votes p)) "APPROVED" "REJECTED")))
          (map-set proposals proposal-id
            (tuple
              (creator (get creator p))
              (title (get title p))
              (description (get description p))
              (for-votes (get for-votes p))
              (against-votes (get against-votes p))
              (total-staked (get total-staked p))
              (deadline (get deadline p))
              (executed true)))
          (ok (tuple (proposal-id proposal-id) (status result))))
        (err ERR_VOTING_CLOSED)))
)

;; 5. Claim reward for voting participation
(define-public (claim-reward (proposal-id uint))
  (let ((vt (unwrap! (map-get? votes (tuple (proposal-id proposal-id) (voter tx-sender))) (err ERR_NOT_FOUND)))
        (vote-key (tuple (proposal-id proposal-id) (voter tx-sender))))
    (if (not (get rewarded vt))
        (let ((reward (calc-reward (get weight vt))))
          (try! (stx-transfer? reward contract-caller tx-sender))
          (map-set votes vote-key
            (tuple
              (support (get support vt))
              (weight (get weight vt))
              (timestamp (get timestamp vt))
              (rewarded true)))
          (ok (tuple (reward reward))))
        (err ERR_ALREADY_VOTED)))
)
(define-read-only (get-proposal (id uint))
  (map-get? proposals id)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes (tuple (proposal-id proposal-id) (voter voter)))
)

(define-read-only (get-total-proposals)
  (var-get total-proposals)
)

(define-read-only (get-weight-of (voter principal))
  (get-weight voter)
)
