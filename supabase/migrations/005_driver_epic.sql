-- ============================================================
-- ParkFlow — Migración v5.0
-- Descripción: Driver Epic (HU-05 a HU-08)
--              - nearby_spots RPC: devuelve lat/lng explícitos (ST_X, ST_Y)
--              - extend_booking RPC: driver extiende reserva
-- ============================================================

-- Reemplaza nearby_spots para exponer lat/lng como floats explícitos
-- (la columna geom es PostGIS WKB binary, no parseable en Dart)
DROP FUNCTION IF EXISTS public.nearby_spots(FLOAT, FLOAT, INT);

CREATE OR REPLACE FUNCTION public.nearby_spots(lat FLOAT, lng FLOAT, radius_m INT DEFAULT 800)
RETURNS TABLE (
  id UUID, host_id UUID, address TEXT, photo_urls TEXT[],
  width NUMERIC, height NUMERIC, vehicle_types JSONB, features JSONB,
  base_price_per_hour NUMERIC, is_active BOOLEAN,
  availability_start TIME, availability_end TIME, available_days INTEGER[],
  rating NUMERIC, rating_count INTEGER, created_at TIMESTAMPTZ,
  latitude FLOAT, longitude FLOAT
) LANGUAGE sql STABLE AS $$
  SELECT
    id, host_id, address, photo_urls,
    width, height, vehicle_types, features,
    base_price_per_hour, is_active,
    availability_start, availability_end, available_days,
    rating, rating_count, created_at,
    ST_Y(geom::geometry) AS latitude,
    ST_X(geom::geometry) AS longitude
  FROM public.parking_spots
  WHERE is_active = TRUE
    AND ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography, radius_m)
  ORDER BY geom <-> ST_SetSRID(ST_MakePoint(lng, lat), 4326)
  LIMIT 50;
$$;

-- RPC: driver solicita extensión de una reserva
-- Inserta nueva fila de bid con status 'pending' contra la misma cochera/anfitrión
-- (el anfitrión la ve en el panel de solicitudes y puede aceptarla)
CREATE OR REPLACE FUNCTION public.extend_booking(
  p_booking_id UUID,
  p_extra_hours NUMERIC
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  bk public.bookings%ROWTYPE;
  new_bid_id UUID;
BEGIN
  SELECT * INTO bk FROM public.bookings WHERE id = p_booking_id;

  IF bk.id IS NULL THEN
    RAISE EXCEPTION 'Booking no encontrada';
  END IF;

  IF bk.driver_id <> auth.uid() THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;

  INSERT INTO public.bids (
    driver_id, host_id, spot_id,
    proposed_price_per_hour, start_time, hours_requested, vehicle_plate, status
  ) VALUES (
    bk.driver_id, bk.host_id, bk.spot_id,
    bk.price_per_hour, bk.end_time, p_extra_hours, bk.vehicle_plate, 'pending'
  ) RETURNING id INTO new_bid_id;

  RETURN new_bid_id;
END;
$$;
