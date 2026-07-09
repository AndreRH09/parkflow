-- ============================================================
-- 007: nearby_spots expone host_name (HU-07: nombre del dueño)
--      JOIN parking_spots → profiles para mostrar dueño en ficha
-- ============================================================

DROP FUNCTION IF EXISTS public.nearby_spots(FLOAT, FLOAT, INT);

CREATE OR REPLACE FUNCTION public.nearby_spots(lat FLOAT, lng FLOAT, radius_m INT DEFAULT 800)
RETURNS TABLE (
  id UUID, host_id UUID, address TEXT, photo_urls TEXT[],
  width NUMERIC, height NUMERIC, vehicle_types JSONB, features JSONB,
  base_price_per_hour NUMERIC, is_active BOOLEAN,
  availability_start TIME, availability_end TIME, available_days INTEGER[],
  rating NUMERIC, rating_count INTEGER, created_at TIMESTAMPTZ,
  latitude FLOAT, longitude FLOAT,
  host_name TEXT
) LANGUAGE sql STABLE AS $$
  SELECT
    s.id, s.host_id, s.address, s.photo_urls,
    s.width, s.height, s.vehicle_types, s.features,
    s.base_price_per_hour, s.is_active,
    s.availability_start, s.availability_end, s.available_days,
    s.rating, s.rating_count, s.created_at,
    ST_Y(s.geom::geometry) AS latitude,
    ST_X(s.geom::geometry) AS longitude,
    p.full_name AS host_name
  FROM public.parking_spots s
  LEFT JOIN public.profiles p ON p.id = s.host_id
  WHERE s.is_active = TRUE
    AND ST_DWithin(s.geom::geography, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography, radius_m)
  ORDER BY s.geom <-> ST_SetSRID(ST_MakePoint(lng, lat), 4326)
  LIMIT 50;
$$;
