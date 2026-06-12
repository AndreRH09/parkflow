-- ============================================================
-- ParkFlow — Migración v2.0
-- Descripción: Agregar soporte multi-foto para cocheras y funciones RPC
-- ============================================================

-- ============================================================
-- TABLA: parking_spots — agregar columna photo_urls
-- ============================================================
ALTER TABLE public.parking_spots
ADD COLUMN IF NOT EXISTS photo_urls TEXT[] DEFAULT '{}';

-- ============================================================
-- STORAGE: bucket para fotos de cochera
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('garage-photos', 'garage-photos', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "garage_photo_public_read" ON storage.objects;
DROP POLICY IF EXISTS "garage_photo_owner_upload" ON storage.objects;
DROP POLICY IF EXISTS "garage_photo_owner_update" ON storage.objects;
DROP POLICY IF EXISTS "garage_photo_owner_delete" ON storage.objects;

CREATE POLICY "garage_photo_public_read"  ON storage.objects FOR SELECT USING (bucket_id = 'garage-photos');
CREATE POLICY "garage_photo_owner_upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'garage-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "garage_photo_owner_update" ON storage.objects FOR UPDATE USING  (bucket_id = 'garage-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "garage_photo_owner_delete" ON storage.objects FOR DELETE USING  (bucket_id = 'garage-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ============================================================
-- RPC: insertar parking spot con geom + marcar garage_config_complete
-- ============================================================
CREATE OR REPLACE FUNCTION insert_parking_spot(
  p_host_id            UUID,
  p_address            TEXT,
  p_base_price         NUMERIC,
  p_vehicle_types      JSONB,
  p_features           JSONB,
  p_width              NUMERIC,
  p_height             NUMERIC,
  p_photo_urls         TEXT[],
  p_lat                FLOAT,
  p_lng                FLOAT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  spot_id UUID;
BEGIN
  INSERT INTO public.parking_spots (
    host_id, address, base_price_per_hour, vehicle_types, features,
    width, height, photo_urls, photo_url, geom, is_active
  ) VALUES (
    p_host_id, p_address, p_base_price, p_vehicle_types, p_features,
    p_width, p_height, p_photo_urls,
    CASE WHEN array_length(p_photo_urls, 1) > 0 THEN p_photo_urls[1] ELSE NULL END,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326),
    TRUE
  ) RETURNING id INTO spot_id;

  UPDATE public.profiles
  SET garage_config_complete = TRUE, updated_at = NOW()
  WHERE id = p_host_id;

  RETURN spot_id;
END;
$$;

-- ============================================================
-- RPC: eliminar cuenta de usuario (cascade deletes via ON DELETE CASCADE)
-- ============================================================
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;
