-- ============================================================
-- ParkFlow — Migración v3.0
-- Descripción: Agregar ON DELETE CASCADE a foreign keys
-- ============================================================

-- ============================================================
-- parking_spots: agregar CASCADE delete en host_id FK
-- ============================================================
ALTER TABLE public.parking_spots
DROP CONSTRAINT IF EXISTS parking_spots_host_id_fkey,
ADD CONSTRAINT parking_spots_host_id_fkey
  FOREIGN KEY (host_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- ============================================================
-- bids: agregar CASCADE delete en FK
-- ============================================================
ALTER TABLE public.bids
DROP CONSTRAINT IF EXISTS bids_driver_id_fkey,
ADD CONSTRAINT bids_driver_id_fkey
  FOREIGN KEY (driver_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.bids
DROP CONSTRAINT IF EXISTS bids_host_id_fkey,
ADD CONSTRAINT bids_host_id_fkey
  FOREIGN KEY (host_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.bids
DROP CONSTRAINT IF EXISTS bids_spot_id_fkey,
ADD CONSTRAINT bids_spot_id_fkey
  FOREIGN KEY (spot_id) REFERENCES public.parking_spots(id) ON DELETE CASCADE;

-- ============================================================
-- bookings: agregar CASCADE delete en FK
-- ============================================================
ALTER TABLE public.bookings
DROP CONSTRAINT IF EXISTS bookings_driver_id_fkey,
ADD CONSTRAINT bookings_driver_id_fkey
  FOREIGN KEY (driver_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.bookings
DROP CONSTRAINT IF EXISTS bookings_host_id_fkey,
ADD CONSTRAINT bookings_host_id_fkey
  FOREIGN KEY (host_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.bookings
DROP CONSTRAINT IF EXISTS bookings_spot_id_fkey,
ADD CONSTRAINT bookings_spot_id_fkey
  FOREIGN KEY (spot_id) REFERENCES public.parking_spots(id) ON DELETE CASCADE;

ALTER TABLE public.bookings
DROP CONSTRAINT IF EXISTS bookings_bid_id_fkey,
ADD CONSTRAINT bookings_bid_id_fkey
  FOREIGN KEY (bid_id) REFERENCES public.bids(id) ON DELETE CASCADE;

-- ============================================================
-- reviews: agregar CASCADE delete en FK
-- ============================================================
ALTER TABLE public.reviews
DROP CONSTRAINT IF EXISTS reviews_booking_id_fkey,
ADD CONSTRAINT reviews_booking_id_fkey
  FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;

ALTER TABLE public.reviews
DROP CONSTRAINT IF EXISTS reviews_reviewer_id_fkey,
ADD CONSTRAINT reviews_reviewer_id_fkey
  FOREIGN KEY (reviewer_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.reviews
DROP CONSTRAINT IF EXISTS reviews_reviewee_id_fkey,
ADD CONSTRAINT reviews_reviewee_id_fkey
  FOREIGN KEY (reviewee_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
