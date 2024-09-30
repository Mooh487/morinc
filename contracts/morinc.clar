;; Decentralized Compute and Storage Smart Contract

;; ======================
;; Constants
;; ======================

(define-constant MAX-SPACE u1000000000) ;; 1 TB in MB
(define-constant MAX-CORES u128)
(define-constant MAX-PRICE u1000000000) ;; 1000 STX
(define-constant MAX-LEASE-DURATION u52560) ;; ~1 year in blocks

(define-constant ERR-NOT-FOUND u404)
(define-constant ERR-UNAUTHORIZED u403)
(define-constant ERR-BAD-REQUEST u400)
(define-constant ERR-INSUFFICIENT-FUNDS u401)

;; ======================
;; Data Maps
;; ======================

;; Storage Nodes
(define-map storage-nodes 
  { node-id: uint } 
  { owner: principal, available-space: uint, price-per-gb: uint })

;; Compute Nodes
(define-map compute-nodes 
  { node-id: uint }
  { owner: principal, available-cores: uint, price-per-core: uint })

;; Storage Leases
(define-map storage-leases 
  { lease-id: uint }
  { client: principal, node-id: uint, space-rented: uint, lease-start-block: uint, lease-end-block: uint, payment-amount: uint })

;; Compute Leases
(define-map compute-leases 
  { lease-id: uint }
  { client: principal, node-id: uint, cores-rented: uint, lease-start-block: uint, lease-end-block: uint, payment-amount: uint })

;; ======================
;; Variables
;; ======================

(define-data-var next-node-id uint u0)
(define-data-var next-lease-id uint u0)

;; ======================
;; Private Functions
;; ======================

;; Function to get the next node ID
(define-private (get-and-increment-node-id)
  (let 
    ((current-id (var-get next-node-id)))
    (var-set next-node-id (+ current-id u1))
    current-id))

;; Function to get the next lease ID
(define-private (get-and-increment-lease-id)
  (let 
    ((current-id (var-get next-lease-id)))
    (var-set next-lease-id (+ current-id u1))
    current-id))

;; ======================
;; Public Functions
;; ======================

;; Storage Node Management
;; ======================

;; Function to register a new storage node
(define-public (register-storage-node (available-space uint) (price-per-gb uint))
  (let 
    ((node-id (get-and-increment-node-id)))
    (asserts! (> available-space u0) (err ERR-BAD-REQUEST))
    (asserts! (> price-per-gb u0) (err ERR-BAD-REQUEST))
    (asserts! (<= available-space MAX-SPACE) (err ERR-BAD-REQUEST))
    (asserts! (<= price-per-gb MAX-PRICE) (err ERR-BAD-REQUEST))
    (map-set storage-nodes 
      { node-id: node-id } 
      { owner: tx-sender, available-space: available-space, price-per-gb: price-per-gb })
    (ok node-id)))

;; Function to update an existing storage node
(define-public (update-storage-node (node-id uint) (available-space uint) (price-per-gb uint))
  (let 
    ((node (unwrap! (map-get? storage-nodes { node-id: node-id }) (err ERR-NOT-FOUND))))
    (asserts! (is-eq tx-sender (get owner node)) (err ERR-UNAUTHORIZED))
    (asserts! (> available-space u0) (err ERR-BAD-REQUEST))
    (asserts! (> price-per-gb u0) (err ERR-BAD-REQUEST))
    (asserts! (<= available-space MAX-SPACE) (err ERR-BAD-REQUEST))
    (asserts! (<= price-per-gb MAX-PRICE) (err ERR-BAD-REQUEST))
    (ok (map-set storage-nodes 
         { node-id: node-id } 
         (merge node { available-space: available-space, price-per-gb: price-per-gb })))))

;; Compute Node Management
;; ======================

;; Function to register a new compute node  
(define-public (register-compute-node (available-cores uint) (price-per-core uint))
  (let 
    ((node-id (get-and-increment-node-id)))
    (asserts! (> available-cores u0) (err ERR-BAD-REQUEST))
    (asserts! (> price-per-core u0) (err ERR-BAD-REQUEST))
    (asserts! (<= available-cores MAX-CORES) (err ERR-BAD-REQUEST))
    (asserts! (<= price-per-core MAX-PRICE) (err ERR-BAD-REQUEST))
    (map-set compute-nodes 
      { node-id: node-id } 
      { owner: tx-sender, available-cores: available-cores, price-per-core: price-per-core })
    (ok node-id)))

;; Function to update an existing compute node
(define-public (update-compute-node (node-id uint) (available-cores uint) (price-per-core uint))
  (let 
    ((node (unwrap! (map-get? compute-nodes { node-id: node-id }) (err ERR-NOT-FOUND))))
    (asserts! (is-eq tx-sender (get owner node)) (err ERR-UNAUTHORIZED))
    (asserts! (> available-cores u0) (err ERR-BAD-REQUEST))
    (asserts! (> price-per-core u0) (err ERR-BAD-REQUEST))
    (asserts! (<= available-cores MAX-CORES) (err ERR-BAD-REQUEST))
    (asserts! (<= price-per-core MAX-PRICE) (err ERR-BAD-REQUEST))
    (ok (map-set compute-nodes 
         { node-id: node-id } 
         (merge node { available-cores: available-cores, price-per-core: price-per-core })))))

;; Lease Management
;; ======================

;; Function to lease storage from a node
(define-public (lease-storage (node-id uint) (space-to-rent uint) (lease-duration uint))
  (let 
    ((node (unwrap! (map-get? storage-nodes { node-id: node-id }) (err ERR-NOT-FOUND)))
     (lease-id (get-and-increment-lease-id)))
    (asserts! (> space-to-rent u0) (err ERR-BAD-REQUEST))
    (asserts! (> lease-duration u0) (err ERR-BAD-REQUEST))
    (asserts! (<= space-to-rent (get available-space node)) (err ERR-BAD-REQUEST))
    (asserts! (<= lease-duration MAX-LEASE-DURATION) (err ERR-BAD-REQUEST))
    (let 
      ((payment-amount (* space-to-rent (get price-per-gb node))))
      (asserts! (<= payment-amount (stx-get-balance tx-sender)) (err ERR-INSUFFICIENT-FUNDS))
      (map-set storage-leases 
        { lease-id: lease-id }
        { client: tx-sender, 
          node-id: node-id, 
          space-rented: space-to-rent, 
          lease-start-block: block-height, 
          lease-end-block: (+ block-height lease-duration), 
          payment-amount: payment-amount })
      (ok lease-id))))

;; Function to lease compute resources from a node  
(define-public (lease-compute (node-id uint) (cores-to-rent uint) (lease-duration uint))
  (let 
    ((node (unwrap! (map-get? compute-nodes { node-id: node-id }) (err ERR-NOT-FOUND)))
     (lease-id (get-and-increment-lease-id)))
    (asserts! (> cores-to-rent u0) (err ERR-BAD-REQUEST))
    (asserts! (> lease-duration u0) (err ERR-BAD-REQUEST))
    (asserts! (<= cores-to-rent (get available-cores node)) (err ERR-BAD-REQUEST))
    (asserts! (<= lease-duration MAX-LEASE-DURATION) (err ERR-BAD-REQUEST))
    (let 
      ((payment-amount (* cores-to-rent (get price-per-core node))))
      (asserts! (<= payment-amount (stx-get-balance tx-sender)) (err ERR-INSUFFICIENT-FUNDS))
      (map-set compute-leases 
        { lease-id: lease-id }
        { client: tx-sender, 
          node-id: node-id, 
          cores-rented: cores-to-rent, 
          lease-start-block: block-height, 
          lease-end-block: (+ block-height lease-duration), 
          payment-amount: payment-amount })
      (ok lease-id))))

;; Payment Functions
;; ======================

;; Function to pay for a storage lease
(define-public (pay-storage-lease (lease-id uint))
  (let 
    ((lease (unwrap! (map-get? storage-leases { lease-id: lease-id }) (err ERR-NOT-FOUND)))
     (node (unwrap! (map-get? storage-nodes { node-id: (get node-id lease) }) (err ERR-NOT-FOUND))))
    (asserts! (is-eq tx-sender (get client lease)) (err ERR-UNAUTHORIZED))
    (asserts! (> (get payment-amount lease) u0) (err ERR-BAD-REQUEST))
    (asserts! (<= (get payment-amount lease) (stx-get-balance tx-sender)) (err ERR-INSUFFICIENT-FUNDS))
    (try! (stx-transfer? (get payment-amount lease) tx-sender (get owner node)))
    (ok (map-set storage-leases { lease-id: lease-id } (merge lease { payment-amount: u0 })))))

;; Function to pay for a compute lease  
(define-public (pay-compute-lease (lease-id uint))
  (let 
    ((lease (unwrap! (map-get? compute-leases { lease-id: lease-id }) (err ERR-NOT-FOUND)))
     (node (unwrap! (map-get? compute-nodes { node-id: (get node-id lease) }) (err ERR-NOT-FOUND))))
    (asserts! (is-eq tx-sender (get client lease)) (err ERR-UNAUTHORIZED))
    (asserts! (> (get payment-amount lease) u0) (err ERR-BAD-REQUEST))
    (asserts! (<= (get payment-amount lease) (stx-get-balance tx-sender)) (err ERR-INSUFFICIENT-FUNDS))
    (try! (stx-transfer? (get payment-amount lease) tx-sender (get owner node)))
    (ok (map-set compute-leases { lease-id: lease-id } (merge lease { payment-amount: u0 })))))

;; Lease Extension
;; ======================

;; Function to extend a storage lease
(define-public (extend-storage-lease (lease-id uint) (new-duration uint))
  (let 
    ((lease (unwrap! (map-get? storage-leases { lease-id: lease-id }) (err ERR-NOT-FOUND))))
    (asserts! (is-eq tx-sender (get client lease)) (err ERR-UNAUTHORIZED))
    (asserts! (> new-duration u0) (err ERR-BAD-REQUEST))
    (asserts! (<= (+ (get lease-end-block lease) new-duration) (+ block-height MAX-LEASE-DURATION)) (err ERR-BAD-REQUEST))
    (ok (map-set storage-leases 
         { lease-id: lease-id } 
         (merge lease { lease-end-block: (+ (get lease-end-block lease) new-duration) })))))

;; Function to extend a compute lease
(define-public (extend-compute-lease (lease-id uint) (new-duration uint))
  (let 
    ((lease (unwrap! (map-get? compute-leases { lease-id: lease-id }) (err ERR-NOT-FOUND))))
    (asserts! (is-eq tx-sender (get client lease)) (err ERR-UNAUTHORIZED))
    (asserts! (> new-duration u0) (err ERR-BAD-REQUEST))
    (asserts! (<= (+ (get lease-end-block lease) new-duration) (+ block-height MAX-LEASE-DURATION)) (err ERR-BAD-REQUEST))
    (ok (map-set compute-leases 
         { lease-id: lease-id } 
         (merge lease { lease-end-block: (+ (get lease-end-block lease) new-duration) })))))

;; Read-only Functions
;; ======================

;; Function to get storage node details
(define-read-only (get-storage-node (node-id uint))
  (map-get? storage-nodes { node-id: node-id }))

;; Function to get compute node details
(define-read-only (get-compute-node (node-id uint))
  (map-get? compute-nodes { node-id: node-id }))

;; Function to get storage lease details
(define-read-only (get-storage-lease (lease-id uint))
  (map-get? storage-leases { lease-id: lease-id }))

;; Function to get compute lease details
(define-read-only (get-compute-lease (lease-id uint))
  (map-get? compute-leases { lease-id: lease-id }))