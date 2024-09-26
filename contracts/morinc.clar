;; Define data structures for storage and compute nodes
(define-map storage-nodes 
  { node-id: uint } 
  { owner: principal, available-space: uint, price-per-gb: uint })

(define-map compute-nodes 
  { node-id: uint }
  { owner: principal, available-cores: uint, price-per-core: uint })

;; Define data structures for storage and compute leases
(define-map storage-leases 
  { lease-id: uint }
  { client: principal, node-id: uint, space-rented: uint, lease-start-block: uint, lease-end-block: uint, payment-amount: uint })

(define-map compute-leases 
  { lease-id: uint }
  { client: principal, node-id: uint, cores-rented: uint, lease-start-block: uint, lease-end-block: uint, payment-amount: uint })

;; Define counters for node IDs and lease IDs
(define-data-var next-node-id uint u0)
(define-data-var next-lease-id uint u0)

;; Define constants for maximum values
(define-constant MAX-SPACE u1000000000) ;; 1 TB in MB
(define-constant MAX-CORES u128)
(define-constant MAX-PRICE u1000000000) ;; 1000 STX
(define-constant MAX-LEASE-DURATION u52560) ;; ~1 year in blocks

;; Functions for managing storage nodes
;; Function to register a new storage node
(define-public (register-storage-node (available-space uint) (price-per-gb uint))
  (let 
    ((node-id (var-get next-node-id)))
    (asserts! (<= available-space MAX-SPACE) (err u400))
    (asserts! (<= price-per-gb MAX-PRICE) (err u400))
    (map-set storage-nodes { node-id: node-id } { owner: tx-sender, available-space: available-space, price-per-gb: price-per-gb })
    (var-set next-node-id (+ node-id u1))
    (ok node-id)))

;; Function to update an existing storage node
(define-public (update-storage-node (node-id uint) (available-space uint) (price-per-gb uint))
  (let 
    ((node (unwrap! (map-get? storage-nodes { node-id: node-id }) (err u404))))
    (asserts! (is-eq tx-sender (get owner node)) (err u403))
    (asserts! (<= available-space MAX-SPACE) (err u400))
    (asserts! (<= price-per-gb MAX-PRICE) (err u400))
    (ok (map-set storage-nodes { node-id: node-id } (merge node { available-space: available-space, price-per-gb: price-per-gb })))))


    ;; Functions for managing compute nodes
;; Function to register a new compute node  
(define-public (register-compute-node (available-cores uint) (price-per-core uint))
  (let 
    ((node-id (var-get next-node-id)))
    (asserts! (<= available-cores MAX-CORES) (err u400))
    (asserts! (<= price-per-core MAX-PRICE) (err u400))
    (map-set compute-nodes { node-id: node-id } { owner: tx-sender, available-cores: available-cores, price-per-core: price-per-core })
    (var-set next-node-id (+ node-id u1))
    (ok node-id)))


;; Function to update an existing compute node
(define-public (update-compute-node (node-id uint) (available-cores uint) (price-per-core uint))
  (let 
    ((node (unwrap! (map-get? compute-nodes { node-id: node-id }) (err u404))))
    (asserts! (is-eq tx-sender (get owner node)) (err u403))
    (asserts! (<= available-cores MAX-CORES) (err u400))
    (asserts! (<= price-per-core MAX-PRICE) (err u400))
    (ok (map-set compute-nodes { node-id: node-id } (merge node { available-cores: available-cores, price-per-core: price-per-core })))))

;; Function to lease storage from a node
(define-public (lease-storage (node-id uint) (space-to-rent uint) (lease-duration uint))
  (let 
    ((node (unwrap! (map-get? storage-nodes { node-id: node-id }) (err u404)))
     (lease-id (var-get next-lease-id)))
    (asserts! (<= space-to-rent (get available-space node)) (err u400))
    (asserts! (<= lease-duration MAX-LEASE-DURATION) (err u400))
    (map-set storage-leases 
      { lease-id: lease-id }
      { client: tx-sender, 
        node-id: node-id, 
        space-rented: space-to-rent, 
        lease-start-block: block-height, 
        lease-end-block: (+ block-height lease-duration), 
        payment-amount: (* space-to-rent (get price-per-gb node)) })
    (var-set next-lease-id (+ lease-id u1))
    (ok lease-id)))

    ;; Function to lease compute resources from a node  
(define-public (lease-compute (node-id uint) (cores-to-rent uint) (lease-duration uint))
  (let 
    ((node (unwrap! (map-get? compute-nodes { node-id: node-id }) (err u404)))
     (lease-id (var-get next-lease-id)))
    (asserts! (<= cores-to-rent (get available-cores node)) (err u400))
    (asserts! (<= lease-duration MAX-LEASE-DURATION) (err u400))
    (map-set compute-leases 
      { lease-id: lease-id }
      { client: tx-sender, 
        node-id: node-id, 
        cores-rented: cores-to-rent, 
        lease-start-block: block-height, 
        lease-end-block: (+ block-height lease-duration), 
        payment-amount: (* cores-to-rent (get price-per-core node)) })
    (var-set next-lease-id (+ lease-id u1))
    (ok lease-id)))


    ;; Function to pay for a storage lease
(define-public (pay-storage-lease (lease-id uint))
  (let 
    ((lease (unwrap! (map-get? storage-leases { lease-id: lease-id }) (err u404)))
     (node (unwrap! (map-get? storage-nodes { node-id: (get node-id lease) }) (err u404))))
    (asserts! (is-eq tx-sender (get client lease)) (err u403))
    (try! (stx-transfer? (get payment-amount lease) tx-sender (get owner node)))
    (ok (map-set storage-leases { lease-id: lease-id } (merge lease { payment-amount: u0 })))))


;; Function to pay for a compute lease  
(define-public (pay-compute-lease (lease-id uint))
  (let 
    ((lease (unwrap! (map-get? compute-leases { lease-id: lease-id }) (err u404)))
     (node (unwrap! (map-get? compute-nodes { node-id: (get node-id lease) }) (err u404))))
    (asserts! (is-eq tx-sender (get client lease)) (err u403))
    (try! (stx-transfer? (get payment-amount lease) tx-sender (get owner node)))
    (ok (map-set compute-leases { lease-id: lease-id } (merge lease { payment-amount: u0 })))))
