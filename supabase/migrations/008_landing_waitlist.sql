-- ============================================================
-- Migración: Registro de interesados en el piloto (landing page)
-- Descripción: Guarda los leads del formulario de la landing
-- (host o driver) mientras la app no está publicada en tiendas.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.waitlist_signups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('host', 'driver')),
  message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.waitlist_signups ENABLE ROW LEVEL SECURITY;

-- Cualquiera puede registrarse desde la landing (INSERT).
-- No se define política de SELECT/UPDATE/DELETE para el rol
-- anónimo: con RLS activo eso las deja denegadas por defecto,
-- así los leads solo son legibles desde el dashboard o con la
-- service role key.
CREATE POLICY "anyone_can_join_waitlist" ON public.waitlist_signups
  FOR INSERT
  WITH CHECK (true);
