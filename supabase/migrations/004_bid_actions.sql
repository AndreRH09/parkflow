-- ============================================================
-- ParkFlow — Migración v4.0
-- Descripción: RPC accept_bid (HU-12). Acepta una puja y crea la reserva.
--              bookings no tiene política INSERT → debe crearse server-side.
-- ============================================================

CREATE OR REPLACE FUNCTION public.accept_bid(p_bid_id UUID)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  b           public.bids%ROWTYPE;
  booking_id  UUID;
BEGIN
  SELECT * INTO b FROM public.bids WHERE id = p_bid_id;

  IF b.id IS NULL THEN
    RAISE EXCEPTION 'Bid no encontrada';
  END IF;

  -- Solo el anfitrión dueño de la puja puede aceptarla.
  IF b.host_id <> auth.uid() THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;

  IF b.status <> 'pending' THEN
    RAISE EXCEPTION 'La puja ya no está pendiente';
  END IF;

  UPDATE public.bids SET status = 'accepted' WHERE id = p_bid_id;

  INSERT INTO public.bookings (
    bid_id, driver_id, host_id, spot_id, price_per_hour,
    start_time, end_time, total_amount, vehicle_plate, status
  ) VALUES (
    b.id, b.driver_id, b.host_id, b.spot_id, b.proposed_price_per_hour,
    b.start_time,
    b.start_time + (b.hours_requested * INTERVAL '1 hour'),
    b.total_amount, b.vehicle_plate, 'reserved'
  ) RETURNING id INTO booking_id;

  RETURN booking_id;
END;
$$;
