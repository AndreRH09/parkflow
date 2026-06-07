-- ============================================================
-- ParkFlow — Supabase Schema v1.0
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ============================================================

-- ============================================================
-- TABLA: profiles
-- Sincronizada automáticamente con auth.users vía trigger
-- ============================================================
CREATE TABLE public.profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email            TEXT,
  full_name        TEXT,
  age              INTEGER,
  dni              TEXT,
  phone            TEXT,
  avatar_url       TEXT,
  role             TEXT CHECK (role IN ('driver', 'host')),
  rating           NUMERIC(3,2) DEFAULT 0,
  rating_count     INTEGER DEFAULT 0,
  profile_complete BOOLEAN DEFAULT FALSE,
  city             TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger: crea fila en profiles automáticamente al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.raw_user_meta_data->>'email');
  RETURN new;
END; $$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_profile_select" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "own_profile_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- ============================================================
-- EXTENSIÓN PostGIS (requerida para HU-05/06)
-- ============================================================
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================
-- TABLA: parking_spots
-- ============================================================
CREATE TABLE public.parking_spots (
  id                   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  host_id              UUID NOT NULL REFERENCES public.profiles(id),
  address              TEXT NOT NULL,
  geom                 GEOMETRY(Point, 4326) NOT NULL,
  photo_url            TEXT,
  width                NUMERIC(4,2),
  height               NUMERIC(4,2),
  vehicle_types        JSONB DEFAULT '[]',
  features             JSONB DEFAULT '{}',
  base_price_per_hour  NUMERIC(8,2),
  is_active            BOOLEAN DEFAULT TRUE,
  availability_start   TIME,
  availability_end     TIME,
  available_days       INTEGER[] DEFAULT '{1,2,3,4,5,6,7}',
  rating               NUMERIC(3,2) DEFAULT 0,
  rating_count         INTEGER DEFAULT 0,
  created_at           TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX parking_spots_geom_idx ON public.parking_spots USING GIST(geom);

ALTER TABLE public.parking_spots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "active_spots_public"  ON public.parking_spots FOR SELECT USING (is_active = TRUE);
CREATE POLICY "host_manage_own_spot" ON public.parking_spots FOR ALL    USING (auth.uid() = host_id);

-- RPC: búsqueda geoespacial para HU-05 (radio 800m por defecto)
CREATE OR REPLACE FUNCTION nearby_spots(lat FLOAT, lng FLOAT, radius_m INT DEFAULT 800)
RETURNS SETOF public.parking_spots LANGUAGE sql STABLE AS $$
  SELECT * FROM public.parking_spots
  WHERE is_active = TRUE
    AND ST_DWithin(geom::geography, ST_MakePoint(lng, lat)::geography, radius_m)
  ORDER BY geom <-> ST_MakePoint(lng, lat)::geometry
  LIMIT 50;
$$;

-- ============================================================
-- TABLA: bids (pujas/ofertas de conductores a anfitriones)
-- ============================================================
CREATE TABLE public.bids (
  id                      UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id               UUID NOT NULL REFERENCES public.profiles(id),
  host_id                 UUID NOT NULL REFERENCES public.profiles(id),
  spot_id                 UUID NOT NULL REFERENCES public.parking_spots(id),
  proposed_price_per_hour NUMERIC(8,2) NOT NULL,
  start_time              TIMESTAMPTZ NOT NULL,
  hours_requested         NUMERIC(4,1) NOT NULL,
  total_amount            NUMERIC(10,2) GENERATED ALWAYS AS (proposed_price_per_hour * hours_requested) STORED,
  vehicle_plate           TEXT,
  vehicle_dimensions      JSONB,
  status                  TEXT CHECK (status IN ('pending','accepted','rejected','countered','expired')) DEFAULT 'pending',
  expires_at              TIMESTAMPTZ DEFAULT NOW() + INTERVAL '15 minutes',
  created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.bids ENABLE ROW LEVEL SECURITY;
CREATE POLICY "bid_participants"   ON public.bids FOR SELECT USING (auth.uid() = driver_id OR auth.uid() = host_id);
CREATE POLICY "driver_insert_bid"  ON public.bids FOR INSERT WITH CHECK (auth.uid() = driver_id);
CREATE POLICY "host_update_bid"    ON public.bids FOR UPDATE USING (auth.uid() = host_id);

-- ============================================================
-- TABLA: bookings (reservas confirmadas)
-- ============================================================
CREATE TABLE public.bookings (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bid_id         UUID NOT NULL REFERENCES public.bids(id),
  driver_id      UUID NOT NULL REFERENCES public.profiles(id),
  host_id        UUID NOT NULL REFERENCES public.profiles(id),
  spot_id        UUID NOT NULL REFERENCES public.parking_spots(id),
  price_per_hour NUMERIC(8,2) NOT NULL,
  start_time     TIMESTAMPTZ NOT NULL,
  end_time       TIMESTAMPTZ NOT NULL,
  total_amount   NUMERIC(10,2) NOT NULL,
  vehicle_plate  TEXT,
  status         TEXT CHECK (status IN ('reserved','active','completed','cancelled')) DEFAULT 'reserved',
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "booking_participants" ON public.bookings
  FOR SELECT USING (auth.uid() = driver_id OR auth.uid() = host_id);

-- ============================================================
-- TABLA: reviews (calificaciones bidireccionales — HU-14)
-- ============================================================
CREATE TABLE public.reviews (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  booking_id  UUID NOT NULL REFERENCES public.bookings(id),
  reviewer_id UUID NOT NULL REFERENCES public.profiles(id),
  reviewee_id UUID NOT NULL REFERENCES public.profiles(id),
  rating      INTEGER CHECK (rating BETWEEN 1 AND 5) NOT NULL,
  comment     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(booking_id, reviewer_id)
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_reviews"   ON public.reviews FOR SELECT USING (TRUE);
CREATE POLICY "reviewer_insert"  ON public.reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- Trigger: recalcula rating promedio del usuario al recibir una nueva reseña
CREATE OR REPLACE FUNCTION public.update_profile_rating()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.profiles
  SET rating       = (SELECT AVG(rating)::NUMERIC(3,2) FROM public.reviews WHERE reviewee_id = NEW.reviewee_id),
      rating_count = (SELECT COUNT(*) FROM public.reviews WHERE reviewee_id = NEW.reviewee_id),
      updated_at   = NOW()
  WHERE id = NEW.reviewee_id;
  RETURN NEW;
END; $$;

CREATE TRIGGER on_review_inserted
  AFTER INSERT ON public.reviews
  FOR EACH ROW EXECUTE PROCEDURE public.update_profile_rating();
