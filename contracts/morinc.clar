;; Define data structures for storage and compute nodes
(define-map storage-nodes 
  { node-id: uint } 
  { owner: principal, available-space: uint, price-per-gb: uint })

(define-map compute-nodes 
  { node-id: uint }
  { owner: principal, available-cores: uint, price-per-core: uint })