-- Add vehicle fields to profiles table for driver onboarding (HU-03)
ALTER TABLE public.profiles
  ADD COLUMN vehicle_type TEXT,
  ADD COLUMN vehicle_plate TEXT;
