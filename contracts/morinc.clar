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

